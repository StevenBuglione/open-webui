locals {
  service_configs = {
    for name, cfg in var.services :
    name => merge(cfg, { name = name })
  }

  secret_arns = distinct(flatten([
    for cfg in local.service_configs : [
      for secret in coalesce(cfg.secrets, []) : secret.value_from
    ]
  ]))
}

resource "aws_ecs_cluster" "this" {
  name = "${var.name}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = var.tags
}

resource "aws_iam_role" "execution" {
  name = "${var.name}-ecs-exec"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "execution" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "execution_secrets" {
  name = "${var.name}-ecs-exec-secrets"
  role = aws_iam_role.execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = local.secret_arns
      },
      {
        Effect   = "Allow"
        Action   = ["kms:Decrypt"]
        Resource = var.kms_key_arn
      }
    ]
  })
}

resource "aws_iam_role" "task" {
  name = "${var.name}-ecs-task"

  assume_role_policy = aws_iam_role.execution.assume_role_policy
}

resource "aws_lb" "this" {
  name               = "${var.name}-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = var.public_subnet_ids
  security_groups    = [var.alb_security_group_id]
  tags               = var.tags
}

resource "aws_lb_target_group" "service" {
  for_each = local.service_configs

  name        = substr("${var.name}-${each.key}", 0, 32)
  protocol    = "HTTP"
  port        = each.value.container_port
  vpc_id      = var.vpc_id
  target_type = "ip"
  health_check {
    path                = try(each.value.health_check_path, "/")
    healthy_threshold   = 3
    unhealthy_threshold = 5
    timeout             = 5
    interval            = 30
    matcher             = "200-399"
  }
  tags = var.tags
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.service[var.primary_service].arn
  }
}

resource "aws_lb_listener_rule" "service" {
  for_each = {
    for name, cfg in local.service_configs :
    name => cfg if cfg.attach_to_alb && name != var.primary_service
  }

  listener_arn = aws_lb_listener.https.arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.service[each.key].arn
  }

  condition {
    path_pattern {
      values = try(each.value.path_patterns, ["/*"])
    }
  }
}

resource "aws_cloudwatch_log_group" "service" {
  for_each          = local.service_configs
  name              = "/aws/ecs/${var.name}/${each.key}"
  retention_in_days = var.log_retention_in_days
  kms_key_id        = var.kms_key_arn
  tags              = var.tags
}

resource "aws_ecs_task_definition" "service" {
  for_each = local.service_configs

  family                   = "${var.name}-${each.key}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = each.value.cpu
  memory                   = each.value.memory
  execution_role_arn       = aws_iam_role.execution.arn
  task_role_arn            = aws_iam_role.task.arn

  dynamic "volume" {
    for_each = try(each.value.efs_volume, null) == null ? [] : [each.value.efs_volume]
    content {
      name = "${each.key}-efs"
      efs_volume_configuration {
        file_system_id     = volume.value.file_system_id
        root_directory     = try(volume.value.root_directory, null)
        transit_encryption = try(volume.value.transit_encryption, true) ? "ENABLED" : "DISABLED"
        authorization_config {
          access_point_id = try(volume.value.access_point_id, null)
          iam             = try(volume.value.use_iam, true) ? "ENABLED" : "DISABLED"
        }
      }
    }
  }

  container_definitions = jsonencode([
    {
      name              = each.key
      image             = each.value.container_image
      cpu               = each.value.cpu
      memoryReservation = each.value.memory
      essential         = true
      portMappings = [
        {
          containerPort = each.value.container_port
          hostPort      = each.value.container_port
          protocol      = "tcp"
        }
      ]
      environment = [
        for k, v in coalesce(each.value.env, {}) : {
          name  = k
          value = v
        }
      ]
      secrets = [
        for secret in coalesce(each.value.secrets, []) : {
          name      = secret.name
          valueFrom = secret.value_from
        }
      ]
      entryPoint = try(each.value.entry_point, null)
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.service[each.key].name
          awslogs-region        = var.region
          awslogs-stream-prefix = each.key
        }
      }
      mountPoints = try(each.value.efs_volume, null) == null ? [] : [{
        containerPath = try(each.value.efs_volume.container_path, "/data")
        sourceVolume  = "${each.key}-efs"
        readOnly      = try(each.value.efs_volume.read_only, false)
      }]
      command = try(each.value.command, null)
    }
  ])
}

resource "aws_ecs_service" "service" {
  for_each        = local.service_configs
  name            = "${var.name}-${each.key}"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.service[each.key].arn
  desired_count   = each.value.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.service_security_group_id]
    assign_public_ip = false
  }

  dynamic "load_balancer" {
    for_each = each.value.attach_to_alb ? [each.value] : []
    content {
      target_group_arn = aws_lb_target_group.service[each.key].arn
      container_name   = each.key
      container_port   = each.value.container_port
    }
  }

  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200
  enable_execute_command             = true

  depends_on = [aws_lb_listener.https]
}
