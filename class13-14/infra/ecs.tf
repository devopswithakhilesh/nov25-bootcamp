# ecs cluster (1)
resource "aws_ecs_cluster" "main" {
  name = "${var.environment}-${var.app_name}-cluster"
  service_connect_defaults {
    namespace = aws_service_discovery_http_namespace.main.arn
  }
}

resource "aws_service_discovery_http_namespace" "main" {
  name        = "${var.environment}-${var.app_name}-namespace"
  description = "ecs namesoace"
}

# ecs task definition (1 per service) -> total 3

resource "aws_ecs_task_definition" "app" {
  for_each                 = local.ecs_services_interpreted
  family                   = "${var.environment}-${var.app_name}-${each.key}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = each.value.cpu
  memory                   = each.value.memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  # task role -> prmissions the running contanrs will have
  # execuation role -> permissions for ecs agent to pull images and send logs

  container_definitions = jsonencode([
    merge(
      {
        name  = each.value.container_name
        image = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${var.environment}-${var.app_name}-${each.key}:latest"

        logConfiguration = {
          logDriver = "awslogs"
          options = {
            awslogs-group        = "/ecs/${var.environment}-${var.app_name}-${each.key}"
            awslogs-region       = var.aws_region
            awslogs-stream-prefix= "ecs"
          }
        }

        essential = true
        portMappings = [
          {
            containerPort = each.value.container_port
            hostPort      = each.value.container_port
            protocol      = "tcp"
            name          = each.value.container_port_name
          }
        ]
      },
      length(each.value.vars) > 0 ? { environment = each.value.vars } : {}
    )
  ])
  depends_on = [aws_cloudwatch_log_group.ecs]
}
# ecs service (1 per service) -> total 3

# flask
resource "aws_ecs_service" "app_service" {
  for_each      = local.ecs_services_interpreted
  name          = "${var.environment}-${var.app_name}-service-${each.key}"
  task_definition = aws_ecs_task_definition.app[each.key].arn
  cluster       = aws_ecs_cluster.main.id
  desired_count = 2
  launch_type   = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = each.value.security_groups
    assign_public_ip = false
  }

  service_connect_configuration {
    enabled   = true
    namespace = aws_service_discovery_http_namespace.main.arn
    service {
      port_name = each.value.container_port_name
      client_alias {
        port     = each.value.container_port
        dns_name = each.value.container_port_name
      }
    }
  }

  dynamic "load_balancer" {
    for_each = each.value.if_alb ? [1] : []
    content {
      target_group_arn = aws_lb_target_group.app_tg.arn
      container_name   = each.value.container_name
      container_port   = each.value.container_port
    }
  }

  depends_on = [aws_db_instance.default]
}
