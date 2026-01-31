

# IAM role for ECS task execution
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.environment}-${var.app_name}-ecsTaskExecutionRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

}

# IAM policy for ECS task execution - ECR pull permissions
resource "aws_iam_role_policy" "ecs_task_execution_policy" {
  name = "${var.environment}-${var.app_name}-ecsTaskExecutionPolicy"
  role = aws_iam_role.ecs_task_execution_role.id
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource" : "*"
      }
    ]
  })
}

