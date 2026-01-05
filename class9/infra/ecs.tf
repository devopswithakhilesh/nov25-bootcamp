# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "student-portal-cluster"
}



# ECS task definition
resource "aws_ecs_task_definition" "app" {
  family                   = "student-portal-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn      = "arn:aws:iam::879381241087:role/formyecsfailingssue"

  container_definitions = jsonencode([
    {
      name  = "student-portal-container"
      image = "879381241087.dkr.ecr.ap-south-1.amazonaws.com/nov25-class5:3.0"
      "environment" : [
        { "name" : "DATABASE_URL", "value" : "postgresql://${aws_db_instance.default.username}:${random_password.rds_password.result}@${aws_db_instance.default.address}:5432/${aws_db_instance.default.db_name}" },
      ],
      essential = true
      portMappings = [
        {
          containerPort = 5000
          hostPort      = 5000
        protocol = "tcp" }
      ]
    }
  ])
}


# ECS service

resource "aws_ecs_service" "app_service" {
  name            = "student-portal-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.private1.id, aws_subnet.private2.id]
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app_tg.arn
    container_name   = "student-portal-container"
    container_port   = 5000
  }
}



# IAM role for ECS task execution
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "student-portal-ecsTaskExecutionRole" 
    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
        {
            Action = "sts:AssumeRole"
            Effect = "Allow"
            Principal = {
            Service = "ec2.amazonaws.com"
            }
        }
        ]
    })

    }

    # IAM policy for ECS task execution - ECR pull permissions
    resource "aws_iam_role_policy" "ecs_task_execution_policy" {
        name   = "student-portal-ecsTaskExecutionPolicy"
        role   = aws_iam_role.ecs_task_execution_role.id
        policy = jsonencode({
            Version = "2012-10-17"
            Statement = [
                {
                    Effect = "Allow"
                    Action = [
                        "ecr:GetAuthorizationToken",
                        "ecr:BatchGetImage",
                        "ecr:GetDownloadUrlForLayer",
                        "ecr:BatchCheckLayerAvailability"
                    ]
                    Resource = "*"
                },
                {
                    Effect = "Allow"
                    Action = [
                        "logs:CreateLogGroup",
                        "logs:CreateLogStream",
                        "logs:PutLogEvents"
                    ]
                    Resource = "arn:aws:logs:*:*:*"
                }
            ]
        })
    }

 