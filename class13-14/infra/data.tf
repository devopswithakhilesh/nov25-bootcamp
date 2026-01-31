data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

# aws account id
# data.aws_caller_identity.current.account_id

data "aws_availability_zones" "available" {
  state = "available"
}

output "zones" {
  value = data.aws_availability_zones.available.names[1]
}