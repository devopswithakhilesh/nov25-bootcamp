locals {

  # list -> [1,2,3,4,5,7,8,34,5] -> set(list)  -> {1,2,3,4,5,7,8,34}
  # set  -> {1,2,3,4,5,7,8)
  ecs_services = [

    # each.value.name
    # each.value.image
    { name           = "flask"
      cpu            = 512
      memory         = 1024
      container_port = 8080
      # image               = ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${var.environment}-${var.app_name}-flask:latest
      container_name      = "flask"
      container_port_name = "flask"
      if_alb              = false
      security_groups     = [aws_security_group.ecs_tasks_flask.id]


      vars = [
        { "name" : "DB_ADDRESS", "value" : "${var.environment == "dev" ? aws_db_instance.default[0].address : aws_rds_cluster.aurora_cluster[0].endpoint}" },
        { "name" : "DB_NAME", "value" : "${var.environment == "dev" ? aws_db_instance.default[0].db_name : aws_rds_cluster.aurora_cluster[0].database_name}" },
        { "name" : "POSTGRES_USERNAME", "value" : "${var.environment == "dev" ? aws_db_instance.default[0].username : aws_rds_cluster.aurora_cluster[0].master_username}" },
        { "name" : "POSTGRES_PASSWORD", "value" : "${random_password.rds_password.result}" },
      ]

    },
    { name           = "redis"
      cpu            = 512
      memory         = 1024
      container_port = 6379
      # image               = ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${var.environment}-${var.app_name}-redis:latest
      container_name      = "redis"
      container_port_name = "redis"
      if_alb              = false
      security_groups     = [aws_security_group.ecs_tasks_redis.id]

      vars = []

    },
    { name           = "nginx"
      cpu            = 512
      memory         = 1024
      container_port = 80
      tag            = "latest"
      # image               = ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${var.environment}-${var.app_name}-nginx:latest
      container_name      = "nginx"
      container_port_name = "nginx"
      if_alb              = true

      security_groups = [aws_security_group.ecs_tasks_nginx.id]

      vars = []

    },


  ]
  ecs_services_interpreted = { for svc in local.ecs_services : svc.name => svc }
  # ecs_services_interpreted = { for svc in local.ecs_services : svc.name => { for k, v in svc : k => v if k != "repo" } }


}

output "ecs_services" {
  value = local.ecs_services_interpreted
  sensitive = true
}