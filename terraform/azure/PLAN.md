# Azure Entra & SSO – Terraform Implementation Plan

## 1. Objectives
- Provision Azure Entra ID artifacts (tenants, app registrations, groups, conditional access) that support AWS-hosted Open WebUI.
- Manage identity + RBAC entirely via Terraform to maintain auditability and repeatability.
- Prepare for SCIM-based lifecycle management so Entra remains system-of-record for OpenWebUI roles and LiteLLM budgets.
- Securely expose OIDC metadata and secrets to AWS workloads via approved secrets exchange flows (Key Vault → Secrets Manager sync).

## 2. Terraform Structure & Providers
```
terraform/azure/
  envs/
    prod/
      backend.tf        # remote state (Azure Storage)
      providers.tf      # azuread + azurerm (for Key Vault, Log Analytics)
      variables.tf
      main.tf           # composes modules
    nonprod/
      backend.tf
      providers.tf
      variables.tf
      main.tf
  modules/
    state/
    identity/
    groups/
    app_registrations/
    scim/
    monitoring/
    rbac_mapping/
```
- Use `azuread` provider for directory objects (requires tenant admin consent and Microsoft Graph API permissions).
- Use `azurerm` provider for ancillary resources (Key Vault, Private DNS, Application Insights for audit events).
- Remote state stored in Azure Storage account with SAS-restricted access, locked via Blob leases.

## 3. Guiding Principles
1. **Source of truth** – Entra groups are authoritative and map 1:1 to OpenWebUI groups; AWS uses OIDC claims for enforcement.
2. **Least privilege** – Service principals used by Terraform and SCIM have minimal API permissions.
3. **Segregation of duties** – App registration that performs SSO is separate from SCIM provisioning and automation accounts.
4. **Conditional Access** – enforce MFA, compliant devices, and network restrictions for OpenWebUI enterprise app.
5. **Secrets never hard-coded** – client secrets stored in Key Vault and synced to AWS Secrets Manager via automation.

## 4. Module Breakdown & Resources

### 4.1 State Module (one-time per tenant)
- Resource group for Terraform state (naming: `rg-openwebui-id-state`).
- Storage account + private container for state files (SAS/min TLS 1.2, firewall-limited to corporate IPs or private endpoints).
- Key Vault-managed key for Storage encryption (optional).

### 4.2 Identity Module
Purpose: baseline directory settings and admin roles.
- Custom domain verification (e.g., `corp.example.com`) for consistent UPNs.
- Entra administrative units (if org uses them) to scope delegated administration for OpenWebUI groups.
- Assign directory roles to automation identities: e.g., `Privileged Role Administrator` is **not** granted; use `Groups Administrator` + `Application Administrator` as needed.

### 4.3 Groups Module
Purpose: master RBAC mapping for OpenWebUI.
Create security groups (mail-enabled optional) such as:
- `OWUI-Admins`
- `OWUI-Developers`
- `OWUI-Business`
- `OWUI-LLM-Observers`

Features:
- Dynamic membership rules (e.g., based on department attributes) where possible.
- Group descriptions documenting intended permissions and mapped LiteLLM budgets.
- Optionally nested groups to simplify assignment across regions/team.
- Export of group object IDs for downstream modules.
RBAC mapping (captured in a separate `rbac_mapping` module or data file):
- Map each Entra group to:
  - OpenWebUI role (admin, workspace-admin, standard user, observer).
  - Allowed model sets (e.g., business-safe vs. full catalog).
  - LiteLLM team/budget identifiers used for cost control on the AWS side.
- Maintain separate groups per environment where appropriate, e.g.:
  - `OWUI-Admins-Prod` vs `OWUI-Admins-NonProd`.
  - `OWUI-Business-Prod` vs `OWUI-Business-NonProd`.

### 4.4 App Registrations Module
Purpose: configure OIDC + SCIM endpoints consumed by AWS services.
Resources:
1. **OpenWebUI OIDC Application**
   - `azuread_application`, `azuread_service_principal`.
   - API permissions: `openid`, `profile`, `email`, `offline_access`, `GroupMember.Read.All` (for group claims) with admin consent recorded via Terraform data source.
   - Redirect URIs pointing to AWS ALB listener (e.g., `https://owui.example.com/oauth/callback`).
   - Token configuration enabling `groups` claim (ID token + access token) with `SecurityGroup` assignment.
   - If group overage is a concern, emit a custom `roles`/`owui_roles` claim using app roles or mapped group IDs to keep tokens small.
   - Client secret stored in Key Vault; optionally create certificate credential for higher security.
   - Conditional Access policy referencing this enterprise app.
2. **SCIM Provisioning Application**
   - Separate app registration for SCIM token.
   - Custom roles (e.g., `SCIMProvisioner`) used by automation account.
   - Generate bearer token stored in Key Vault; downstream automation writes to AWS Secrets Manager.
3. **LiteLLM / API Access Apps**
   - Optional service principals for calling Azure OpenAI (future expansion) managed here for consistent governance.
Environment strategy:
- Either one enterprise application with environment-specific redirect URIs and groups, or:
  - Separate enterprise apps per environment (`OpenWebUI-Prod`, `OpenWebUI-NonProd`) to isolate policies, certificates, and secrets.
  - Terraform variables decide which pattern is used.

### 4.5 SCIM Module
Purpose: deliver automated user/group lifecycle management.
- Configure Entra enterprise application for OpenWebUI with provisioning enabled.
- `azuread_scim_connector` (or Microsoft Graph API config via Terraform) pointing to `https://owui.example.com/scim` with secret from Key Vault.
- Attribute mappings: map `displayName`, `userPrincipalName`, `department`, and custom attributes to OpenWebUI metadata for fine-grained RBAC.
- Attribute mappings should also include:
  - A stable unique identifier (`externalId`) for users that OpenWebUI can rely on.
  - Group membership → OpenWebUI group names/IDs; optionally include environment suffixes (`-Prod`, `-NonProd`).
- Provisioning scope limited to `OWUI-*` groups.
- Notifications (email/webhook) for provisioning errors routed to support channel.

### 4.6 Conditional Access & Security Module
- Policies enforcing MFA, compliant/hybrid joined devices, and trusted networks for the OpenWebUI enterprise application.
- Sign-in risk policy requiring MFA or blocking medium/high risk logins.
- Token lifetime policies (if required) to minimize risk.
- Diagnostic settings exporting sign-in logs to Log Analytics / Event Hub / Sentinel.

### 4.7 Monitoring Module
- Log Analytics workspace collecting Entra sign-in, audit, and provisioning logs.
- Workbook dashboards summarizing OpenWebUI access trends, group membership changes, SCIM failures.
- Alerts for anomalous events (sudden membership spikes, repeated login failures).

### 4.8 Secrets & Key Vault Module
- Azure Key Vault with RBAC-enabled access policies.
- Secrets stored: OIDC client secret, SCIM bearer token, LiteLLM per-team budgets (if mirrored), certificates for SAML/WS-Fed fallback.
- Private endpoint to prevent public internet exposure.
- Azure Automation (or Function App) script replicates secrets into AWS Secrets Manager via AWS IAM cross-account user.

## 5. Cross-Cloud Integration Points
- Publish OIDC metadata URL + JWKS endpoint to AWS Parameter Store for OpenWebUI tasks.
- Provide Entra group object IDs to AWS Terraform via shared variables (e.g., SSM parameters consumed by both stacks).
- Maintain mapping file (JSON) keyed by Entra group → OpenWebUI workspace permissions → LiteLLM budgets, stored in Git and referenced by both AWS + Azure modules.
- Ensure OpenWebUI’s environment variables match Entra configuration:
  - `OAUTH_PROVIDER=oidc`, `OAUTH_ISSUER_URL`, `OAUTH_CLIENT_ID`, `OAUTH_CLIENT_SECRET`.
  - `ENABLE_OAUTH_GROUP_MANAGEMENT=true`, `OAUTH_GROUPS_CLAIM` or custom claim.
  - `ENABLE_SCIM=true` with SCIM endpoint URL and token aligning with the SCIM enterprise app.

## 6. Deployment Workflow
1. Run `state` module to create Azure Storage backend (one time).
2. Authenticate Terraform using workload identity federation (GitHub OIDC → Entra service principal) to avoid client secrets.
3. Apply modules in order: `identity` → `groups` → `app_registrations` → `scim` → `monitoring`.
4. Post-deploy tasks (can be scripted):
   - Admin consent for API permissions.
   - Upload JWKS certificate to OpenWebUI if using certificate creds.
   - Trigger Entra provisioning initial sync to populate OpenWebUI.

## 7. Governance & Compliance
- Record of authority: change requests tracked via PRs referencing JIRA tickets.
- RBAC: only delegated administrators can modify OpenWebUI groups; `Conditional Access` policies locked by security team.
- Key Vault logging + purge protection enabled.
- Access reviews scheduled quarterly for `OWUI-*` groups.

## 8. Future Enhancements
- Add Azure OpenAI enterprise application + private endpoints to feed LiteLLM once multi-cloud routing is enabled.
- Automate secret synchronization using Azure Event Grid + AWS EventBridge pipes for near-real-time rotation.
- Integrate with Microsoft Entra ID Governance (Entitlement Management) to grant OpenWebUI access packages with approval workflows.

## 9. Implementation Checklist (Codex / Terraform)
When asking Codex (or any automation) to implement the Azure side, ensure it follows this checklist exactly:

### 9.1 State & Providers
- [ ] Implement `modules/state`:
  - [ ] Resource group for Terraform state.
  - [ ] Storage account + container with encryption, firewall rules, and TLS 1.2+.
- [ ] Configure `envs/{prod,nonprod}/backend.tf` to use the Storage account/container.
- [ ] Configure `envs/{prod,nonprod}/providers.tf` for `azuread` and `azurerm` with:
  - [ ] Workload identity federation (GitHub OIDC or similar), no long-lived client secrets.

### 9.2 Identity & Directory Baseline
- [ ] Implement `modules/identity`:
  - [ ] Custom domain validation if required.
  - [ ] Administrative units (if the org uses them) to scope OpenWebUI-related groups.
  - [ ] Service principals/managed identities for Terraform and automation, with minimal roles:
    - [ ] `Groups Administrator` and `Application Administrator` where needed.
    - [ ] Avoid broad roles like `Global Administrator` or `Privileged Role Administrator`.

### 9.3 Groups & RBAC Mapping
- [ ] Implement `modules/groups`:
  - [ ] Create base groups: `OWUI-Admins`, `OWUI-Developers`, `OWUI-Business`, `OWUI-LLM-Observers`.
  - [ ] Create environment-specific variants as needed (`*-Prod`, `*-NonProd`).
  - [ ] Add dynamic membership rules where appropriate (e.g., based on department).
  - [ ] Ensure group descriptions document intended use and mapping to OpenWebUI and LiteLLM.
- [ ] Implement `modules/rbac_mapping` (or equivalent data structure):
  - [ ] Map Entra groups → OpenWebUI roles (admin/workspace-admin/user/observer).
  - [ ] Map Entra groups → LiteLLM team/budget identifiers.
  - [ ] Export group object IDs and mapping data as outputs consumable by the AWS stack.

### 9.4 App Registrations (OIDC, SCIM, Future APIs)
- [ ] Implement `modules/app_registrations`:
  - [ ] OpenWebUI OIDC application:
    - [ ] `azuread_application` + `azuread_service_principal`.
    - [ ] Redirect URIs pointing to AWS OpenWebUI URLs (`/oauth/callback`).
    - [ ] API permissions: `openid`, `profile`, `email`, `offline_access`, `GroupMember.Read.All`.
    - [ ] Token configuration:
      - [ ] `groups` claim (ID + access token) or custom `roles`/`owui_roles` claim.
      - [ ] Ensure group overage is handled (app roles or custom claim if necessary).
    - [ ] Client secret in Key Vault and/or certificate-based authentication.
    - [ ] Conditional Access reference to this enterprise app.
  - [ ] SCIM provisioning application:
    - [ ] Separate registration + service principal with minimal permissions.
    - [ ] Secret/token stored in Key Vault.
  - [ ] LiteLLM / Azure OpenAI access applications (future):
    - [ ] Service principals and roles defined but potentially disabled until needed.
- [ ] Decide and implement environment strategy:
  - [ ] Single enterprise app with env-specific URIs **or**
  - [ ] Separate apps per environment (`OpenWebUI-Prod`, `OpenWebUI-NonProd`) controlled via variables.

### 9.5 SCIM Provisioning
- [ ] Implement `modules/scim`:
  - [ ] Enterprise app configuration for OpenWebUI with provisioning enabled.
  - [ ] SCIM connector URL pointing to AWS OpenWebUI SCIM endpoint.
  - [ ] Attribute mappings:
    - [ ] `userPrincipalName`/`mail` → primary identifier.
    - [ ] `externalId` mapped to a stable, immutable ID.
    - [ ] Group membership → OpenWebUI group names/IDs (including environment suffixes if used).
    - [ ] Additional attributes (department, region, cost center) for future fine-grained RBAC.
  - [ ] Scope provisioning to `OWUI-*` groups only.
  - [ ] Configure notification/on-failure hooks (email/webhook) for provisioning errors.

### 9.6 Conditional Access & Security
- [ ] Implement Conditional Access policies targeting the OpenWebUI enterprise app:
  - [ ] Require MFA for all sign-ins.
  - [ ] Require compliant/hybrid joined devices if mandated by policy.
  - [ ] Restrict to trusted networks/locations where appropriate.
  - [ ] Sign-in risk policy (block or require MFA for medium/high risk).
- [ ] Configure token lifetimes and sign-in/session policies as per org standards.

### 9.7 Monitoring & Logs
- [ ] Implement `modules/monitoring`:
  - [ ] Log Analytics workspace for Entra sign-in, audit, and provisioning logs.
  - [ ] Diagnostic settings to send logs from Entra/enterprise apps to Log Analytics (and/or Event Hub/Sentinel).
  - [ ] Dashboards/workbooks for:
    - [ ] OpenWebUI app usage.
    - [ ] Group membership changes.
    - [ ] SCIM provisioning failures.
  - [ ] Alerts for anomalous activity (login failures, membership spikes).

### 9.8 Key Vault & Secrets Flow
- [ ] Implement `modules/secrets` (or extend existing Key Vault module):
  - [ ] Key Vault with RBAC, private endpoint, purge protection, and logging.
  - [ ] Store:
    - [ ] OIDC client secret(s).
    - [ ] SCIM bearer token.
    - [ ] Certificates for OIDC/SAML if used.
    - [ ] Optional per-team budget values mirrored to LiteLLM.
- [ ] Implement automation (Azure Automation/Function) to sync relevant secrets to AWS Secrets Manager:
  - [ ] Use a cross-account IAM principal in AWS with least-privilege access.
  - [ ] Ensure rotations in Key Vault are propagated to AWS on a defined schedule.

### 9.9 Cross-Cloud & OpenWebUI Alignment
- [ ] Ensure the following are available to the AWS Terraform stack (e.g., via SSM/Secrets Manager or a mapping file in Git):
  - [ ] OIDC metadata URL + JWKS endpoint.
  - [ ] Entra group object IDs and their mapped OWUI roles/budgets.
  - [ ] SCIM endpoint URL and token details (for OWUI configuration).
- [ ] Confirm that OpenWebUI ECS task definitions on AWS use env vars consistent with Entra:
  - [ ] `OAUTH_PROVIDER`, `OAUTH_ISSUER_URL`, `OAUTH_CLIENT_ID`, `OAUTH_CLIENT_SECRET`.
  - [ ] `ENABLE_OAUTH_GROUP_MANAGEMENT`, `OAUTH_GROUPS_CLAIM` (or custom claim).
  - [ ] `ENABLE_SCIM`, SCIM token/base URL.
