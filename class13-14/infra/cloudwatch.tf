resource "aws_cloudwatch_log_group" "ecs" {
  for_each                 = local.ecs_services_interpreted

  name              = "/ecs/${var.environment}-${var.app_name}-${each.key}"
  retention_in_days = 1
}

resource "aws_cloudwatch_query_definition" "ecs" {
  for_each                 = local.ecs_services_interpreted

  name = "${var.environment}-${var.app_name}-${each.key}"

  log_group_names = [
    aws_cloudwatch_log_group.ecs[each.key].name,
  ]

  query_string = <<-EOF
    filter @message not like /.+Waiting.+/
    | fields @timestamp, @message
    | sort @timestamp desc
    | limit 200
  EOF
}