locals {
  db_name = var.database_name != "" ? var.database_name : replace(var.name, "-", "_")
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.name}-db-subnets"
  subnet_ids = var.private_subnet_ids
  tags       = var.tags
}

resource "random_password" "db" {
  length  = 32
  special = false
}

locals {
  db_password_uri = urlencode(random_password.db.result)
}

resource "aws_secretsmanager_secret" "db_credentials" {
  name        = "${var.name}/database"
  description = "Credentials for ${var.name} database"
  kms_key_id  = var.kms_key_arn
  tags        = var.tags
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = var.database_username
    password = random_password.db.result
  })
}

resource "aws_secretsmanager_secret" "db_url" {
  name        = "${var.name}/database-url"
  description = "Database connection string"
  kms_key_id  = var.kms_key_arn
  tags        = var.tags
}

resource "aws_secretsmanager_secret_version" "db_url" {
  secret_id = aws_secretsmanager_secret.db_url.id
  secret_string = format(
    "postgresql://%s:%s@%s:%d/%s",
    var.database_username,
    local.db_password_uri,
    aws_db_instance.this.address,
    aws_db_instance.this.port,
    local.db_name
  )
}

resource "aws_db_instance" "this" {
  identifier                 = "${var.name}-postgres"
  engine                     = "postgres"
  engine_version             = var.database_engine_version
  instance_class             = var.database_instance_class
  username                   = var.database_username
  password                   = random_password.db.result
  allocated_storage          = var.database_allocated_storage
  storage_encrypted          = true
  kms_key_id                 = var.kms_key_arn
  db_subnet_group_name       = aws_db_subnet_group.this.name
  vpc_security_group_ids     = [var.rds_security_group_id]
  deletion_protection        = var.database_deletion_protection
  backup_retention_period    = var.database_backup_retention_days
  skip_final_snapshot        = var.skip_final_snapshot
  multi_az                   = var.database_multi_az
  publicly_accessible        = false
  copy_tags_to_snapshot      = true
  auto_minor_version_upgrade = true
  apply_immediately          = false
  db_name                    = local.db_name
  tags                       = var.tags
}

resource "aws_efs_file_system" "this" {
  creation_token  = "${var.name}-efs"
  encrypted       = true
  kms_key_id      = var.kms_key_arn
  throughput_mode = "elastic"
  tags = merge(var.tags, {
    Name = "${var.name}-efs"
  })
}

resource "aws_efs_mount_target" "this" {
  for_each = {
    for idx, subnet_id in var.private_subnet_ids :
    idx => subnet_id
  }

  file_system_id  = aws_efs_file_system.this.id
  subnet_id       = each.value
  security_groups = [var.efs_security_group_id]
}

resource "aws_efs_access_point" "openwebui" {
  file_system_id = aws_efs_file_system.this.id

  posix_user {
    gid            = 0
    uid            = 0
    secondary_gids = []
  }

  root_directory {
    path = "/openwebui"
    creation_info {
      owner_gid   = 0
      owner_uid   = 0
      permissions = "0775"
    }
  }

  tags = var.tags
}
