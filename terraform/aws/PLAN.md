# Open WebUI on AWS – Terraform Implementation Plan

## 0. Current State & Learnings from Azure Work
- Azure side is fully automated: Entra groups, OpenID app registration, LiteLLM SP, SCIM placeholder, and environment-specific outputs are available via `terraform/azure/envs/{nonprod,prod}`. Group object IDs and RBAC mappings now use meaningful LiteLLM team names (e.g., `owui-nonprod-admins`).
- Terraform state for both Azure and AWS now resides in your personal `workspaces` S3 bucket (endpoint `https://s3.oremuslabs.app`), so all modules should assume remote state via that bucket + per-environment key.
- Non-prod OpenWebUI URLs are canonicalized under `owui-nonprod.oremuslabs.app`. DNS is hosted in Cloudflare, so AWS certificates/DNS validation must integrate with Cloudflare APIs (or manual records) rather than Route53.
- Secrets that originate in Entra (OIDC client secret, SCIM token) are **not** provisioned in Azure. We must create empty AWS Secrets Manager placeholders and instruct operators to insert the values after each run.

## 1. Objectives
1. Deploy Open WebUI, LiteLLM, and mcpo as multi-service ECS/Fargate workloads inside a hardened VPC with shared data services (RDS, EFS).
2. Consume Azure Entra SSO/SCIM outputs via AWS Secrets Manager + SSM to ensure a single identity source of truth.
3. Provide optional Cloudflare DNS automation so ALB hostnames (`owui-*.oremuslabs.app`) can be managed alongside the AWS stack.
4. Ship modular Terraform code under `terraform/aws` so environments (nonprod/prod) differ only by tfvars/state; everything else is parameterized.
5. Bake observability (CloudWatch alarms, log groups, SNS topics) and cost controls (LiteLLM config secrets) into the first release.

## 2. Guiding Principles
1. **Single source of truth** – All infra definitions (networking, compute, DNS, secrets) live in Terraform modules. Azure identity outputs feed AWS modules through tfvars/SSM parameters.
2. **Private-by-default** – ECS services run in private subnets without public IPs; ALB is the only internet ingress and sits behind WAF/security groups.
3. **Clean separation of concerns** – Modules mirror architecture layers: `bootstrap`, `network`, `security`, `data`, `compute`, `integrations`, `observability`.
4. **Immutable deployments** – Container images referenced by digest/tag, environment variables/secrets sourced from AWS services instead of inline values.
5. **DNS via Cloudflare** – Certificates requested in ACM (DNS validation) and validated by Cloudflare DNS records created automatically when enabled.

## 3. Directory Layout
```
terraform/aws/
  PLAN.md
  root.hcl
  modules/
    bootstrap/
    network/
    security/
    data/
    compute/
    integrations/
    observability/
    cloudflare_dns/
  envs/
    nonprod/
      terragrunt.hcl
      providers.tf
      versions.tf
      variables.tf
      main.tf
      outputs.tf
      nonprod.tfvars
      nonprod.tfvars.example
    prod/
      terragrunt.hcl
      providers.tf
      versions.tf
      variables.tf
      main.tf
      outputs.tf
      prod.tfvars
      prod.tfvars.example
```

## 4. Module Responsibilities

### 4.1 `bootstrap`
- Creates the remote state S3 bucket + DynamoDB table + KMS key if an account does **not** already have the shared `workspaces` backend.
- IAM policy documents for CI/CD roles (optional) so pipelines can assume bootstrap role.

### 4.2 `network`
- VPC, subnets (public/private per AZ), IGW, NAT gateways, route tables, and gateway/interface endpoints (S3, ECR, CloudWatch, SSM, Bedrock).
- Output: VPC ID, subnet IDs, route table IDs, endpoint IDs.

### 4.3 `security`
- Central KMS CMK for workload data, plus security groups for ALB, ECS services, RDS, and EFS.
- Optionally attaches AWS WAF ACL (future).
- Output: SG IDs, KMS ARN.

### 4.4 `data`
- RDS PostgreSQL (multi-AZ) with Secrets Manager secret storing username/password + connection string.
- EFS filesystem + mount targets + access point for OpenWebUI shared storage.
- (Future) OpenSearch/Qdrant modules can plug in here.

### 4.5 `compute`
- ECS cluster, IAM execution/task roles, CloudWatch log groups.
- Application Load Balancer (HTTPS) + ACM certificate request/validation.
- Generic “service factory” that creates ECS task definitions/services per entry in `var.services`. Each service can:
  - Attach to ALB (default or path-based rules).
  - Consume env/secrets.
  - Mount EFS volumes.
  - Configure autoscaling (future).
- Out of the box we define three services:
  1. `openwebui`
  2. `litellm`
  3. `mcpo`

### 4.6 `integrations`
- Publishes Azure Entra metadata into SSM Parameter Store (client ID, issuer URL, LiteLLM budgets) for cross-stack use.
- Optional Cloudflare DNS record (CNAME) that points to the ALB when `enable_cloudflare_dns = true`. Relies on `CLOUDFLARE_API_TOKEN` env var at runtime.

### 4.7 `observability`
- CloudWatch SNS topic for alerts (or reuse provided ARNs).
- Metric alarms for RDS CPU, ALB 5xx count, ECS memory/cpu per service.
- Shared OTEL log group placeholders.

## 5. Environment Wiring (nonprod/prod)
Each environment main file should:
1. Define `local` tags and names.
2. Instantiate modules in order: `network` → `security` → `data` → `compute` → `integrations` → `observability`.
3. Pass Azure-derived values through tfvars:
   - `openwebui_env` includes OIDC issuer, client ID, SCIM base, `OPENWEBUI_PUBLIC_URL`.
   - `openwebui_secret_arns` references Secrets Manager ARNs for OIDC secret, SCIM token, `DATABASE_URL`.
4. Provide service definitions (maps) for LiteLLM + mcpo with connection info to RDS/EFS or other APIs.
5. Provide Cloudflare zone/record names only when automation is desired (non-empty + `enable_cloudflare_dns = true`).

## 6. Cloudflare & Certificate Strategy
1. Request ACM certificate in the region powering the ALB (us-east-1 or whichever). We use DNS validation.
2. If Cloudflare automation enabled, Terraform writes `_acme-challenge` records plus the final CNAME (`owui-nonprod.oremuslabs.app`) after ALB provisioning.
3. Cloudflare provider credentials should be supplied via `CLOUDFLARE_API_TOKEN` env var; if unset, the DNS module simply does not create resources.
4. Cloudflare SSL/TLS mode should remain “Full (strict)” so Cloudflare trusts ACM certificate.

## 7. Secrets & Identity Flow
1. Azure module outputs (`openwebui_application.client_id`, group IDs) are copied into AWS tfvars.
2. `aws_secretsmanager_secret` resources act as placeholders for:
   - `openid-client-secret`
   - `scim-token`
   - `litellm-config`
3. Terraform does **not** write secret values; operators use `aws secretsmanager put-secret-value` after apply.
4. ECS services consume secrets via `secrets` block in task definition; OpenWebUI gets `DATABASE_URL`, `OAUTH_CLIENT_SECRET`, `SCIM_TOKEN`.

## 8. Deployment Workflow
1. (One time per account) Run `terraform apply` in `modules/bootstrap` (or a dedicated env) to provision state bucket + lock table if needed.
2. For each env, Terragrunt now orchestrates init/plan/apply across directories:
   ```
   cd terraform/aws/envs
   AWS_PROFILE=aws-login terragrunt run-all plan
   AWS_PROFILE=aws-login terragrunt run-all apply
   ```
   (Add `--terragrunt-non-interactive` in CI.)
3. Post-apply steps:
   - Populate Secrets Manager placeholders (OIDC, SCIM, LiteLLM config).
   - Approve ACM validation if Cloudflare automation disabled.
   - Run `aws ecs update-service --force-new-deployment` when secrets/config change.
4. Observability alarms feed SNS → Slack/PagerDuty (configure subscription manually or via IaC extension).

## 9. Checklist for Codex / Automation

### 9.1 Foundation
- [x] Create `terraform/aws/modules/{bootstrap,network,security,data,compute,integrations,observability}` with documented inputs/outputs.
- [x] Create `terraform/aws/envs/{nonprod,prod}` scaffolding referencing modules.
- [x] Remote state uses `workspaces` bucket + `open-webui/aws/<env>.tfstate`.

### 9.2 Networking & Security
- [x] Non-prod tfvars define CIDRs, AZs, ingress CIDRs (corporate + VPN).
- [x] NAT gateway per AZ (optional toggle).
- [x] Security groups in `modules/security` enforce:
  - ALB ingress limited to provided CIDRs.
  - ECS tasks accept from ALB SG only.
  - RDS/EFS accept from ECS SG.
- [x] KMS key for RDS/EFS/Secrets/Log encryption, shared across modules.

### 9.3 Data Plane
- [x] `modules/data` provisions:
  - RDS Postgres (multi-AZ) + Secrets Manager credentials (username/password + connection string).
  - EFS filesystem + mount targets.
- [x] Output ARNs/endpoints for downstream modules.

### 9.4 Compute Plane
- [x] ECS cluster (Fargate only), IAM execution/task roles with least privilege.
- [x] ALB + HTTPS listener using ACM certificate, default action points to OpenWebUI.
- [x] Services map supports OpenWebUI, LiteLLM, mcpo (env + secrets + EFS mount).

### 9.5 Integrations & DNS
- [x] SSM parameters for Azure metadata (client ID, issuer URL, LiteLLM budgets).
- [x] Cloudflare DNS automation optional/feature-flagged; defaults off to avoid token requirement.

### 9.6 Observability
- [x] SNS topic for alerts (or reuse provided ARNs).
- [x] Alarms for RDS CPU, ALB 5xx, ECS Memory/CPU with default thresholds.
- [x] Shared log group names exported for OTEL collectors.

### 9.7 Verification
- [x] `terraform fmt`, `validate`, and `plan` executed for non-prod environment after scaffolding.
- [ ] Document manual steps (Secrets Manager population, Cloudflare token, ACM approval) in README or PLAN.

## 10. Terragrunt Wrapper & Usage
- `terraform/aws/root.hcl` centralizes backend config (S3 bucket `workspaces`, MinIO endpoint, lock table) and exposes shared locals (`aws_region`, `aws_profile`). Remote state always lives under `open-webui/aws/<env>.tfstate`.
- Environment Terragrunt files (`terraform/aws/envs/{nonprod,prod}/terragrunt.hcl`) include the root config, feed the corresponding `*.tfvars`, and add a common `-var-file` extra argument.
- Because Terragrunt copies the *entire* `terraform/aws` tree into its cache, local module paths like `../../modules/network` remain valid without rewriting.
- Typical commands:
  ```
  cd terraform/aws/envs
  AWS_PROFILE=aws-login terragrunt run-all plan
  AWS_PROFILE=aws-login terragrunt run-all apply
  AWS_PROFILE=aws-login terragrunt run-all destroy
  ```

## 11. Cloudflare DNS (optional)
- A dedicated module (`terraform/aws/modules/cloudflare_dns`) exists for creating DNS records. We intentionally keep it decoupled from the main stack so missing `CLOUDFLARE_API_TOKEN` credentials never block AWS deployments.
- When DNS automation is needed, create a small Terragrunt stack (for example `terraform/aws/envs/nonprod/cloudflare/terragrunt.hcl`) that:
  1. Uses a `dependency` block to read `module.compute.alb_dns_name`.
  2. Instantiates the `cloudflare_dns` module with your zone ID/record settings.
  3. Runs `terragrunt apply` with `CLOUDFLARE_API_TOKEN` exported (or provider block configured).

## 12. Next Steps After AWS Stack Ready
1. Populate Secrets Manager with OIDC client secret + SCIM token from Azure outputs.
2. Deploy actual LiteLLM config (YAML) into S3 or Secrets Manager and update ECS task to mount/inject.
3. Hook ECS services into GitHub Actions/CodeBuild pipeline for CI/CD (not covered yet).
4. Enable SCIM + Conditional Access back in Azure once licensing available.
