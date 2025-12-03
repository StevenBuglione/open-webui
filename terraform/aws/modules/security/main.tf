data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

locals {
  kms_service_principals = [
    "secretsmanager.amazonaws.com",
    "rds.amazonaws.com",
    "elasticfilesystem.amazonaws.com"
  ]
}

resource "aws_kms_key" "workload" {
  description             = "${var.name}-workload"
  deletion_window_in_days = 10
  enable_key_rotation     = true
  tags                    = var.tags

  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = concat([
      {
        Sid       = "EnableRootAccount"
        Effect    = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid       = "AllowServiceUse"
        Effect    = "Allow"
        Principal = {
          Service = local.kms_service_principals
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey",
          "kms:CreateGrant"
        ]
        Resource = "*"
      },
      {
        Sid       = "AllowCloudWatchLogs"
        Effect    = "Allow"
        Principal = {
          Service = "logs.${data.aws_region.current.name}.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey",
          "kms:CreateGrant"
        ]
        Resource = "*"
        Condition = {
          ArnLike = {
            "kms:EncryptionContext:aws:logs:arn" = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:*"
          }
        }
      }
    ])
  })
}

resource "aws_security_group" "alb" {
  name        = "${var.name}-alb"
  description = "ALB ingress"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.alb_ingress_cidrs
    content {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.name}-alb" })
}

resource "aws_security_group" "ecs_service" {
  name        = "${var.name}-ecs-service"
  description = "ECS services"
  vpc_id      = var.vpc_id

  ingress {
    description      = "From ALB"
    from_port        = 0
    to_port          = 65535
    protocol         = "tcp"
    security_groups  = [aws_security_group.alb.id]
    ipv6_cidr_blocks = []
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.name}-ecs-service" })
}

resource "aws_security_group" "rds" {
  name        = "${var.name}-rds"
  description = "RDS access"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_service.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.name}-rds" })
}

resource "aws_security_group" "efs" {
  name        = "${var.name}-efs"
  description = "EFS access"
  vpc_id      = var.vpc_id

  ingress {
    description    = "NFS from ECS"
    from_port      = 2049
    to_port        = 2049
    protocol       = "tcp"
    security_groups = [
      aws_security_group.ecs_service.id
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.name}-efs" })
}
