//create protection
data "aws_availability_zones" "available" {}
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

resource "aws_eip" "example" {
  vpc = true
}

resource "aws_shield_protection" "example" {
  name         = "example"
  resource_arn = "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:eip-allocation/${aws_eip.example.id}"

  tags = {
    Environment = "Dev"
  }
}
//create protection group
resource "aws_shield_protection_group" "example" {
  protection_group_id = "example"
  aggregation         = "MAX"
  pattern             = "ALL"
}
// create a protection group for an arbitrary number of resources
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

resource "aws_eip" "example" {
  vpc = true
}

resource "aws_shield_protection" "example" {
  name         = "example"
  resource_arn = "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:eip-allocation/${aws_eip.example.id}"
}

resource "aws_shield_protection_group" "example" {
  depends_on = [aws_shield_protection.example]

  protection_group_id = "example"
  aggregation         = "MEAN"
  pattern             = "ARBITRARY"
  members             = ["arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:eip-allocation/${aws_eip.example.id}"]
}
//create an association between a protected EIP and a Route53 Health check
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

resource "aws_eip" "example" {
  vpc = true
  tags = {
    Name = "example"
  }
}

resource "aws_shield_protection" "example" {
  name         = "example-protection"
  resource_arn = "arn:${data.aws_partition.current.partition}:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:eip-allocation/${aws_eip.example.id}"
}

resource "aws_route53_health_check" "example" {
  ip_address        = aws_eip.example.public_ip
  port              = 80
  type              = "HTTP"
  resource_path     = "/ready"
  failure_threshold = "3"
  request_interval  = "30"

  tags = {
    Name = "tf-example-health-check"
  }
}

resource "aws_shield_protection_health_check_association" "example" {
  health_check_arn     = aws_route53_health_check.example.arn
  shield_protection_id = aws_shield_protection.example.id
}
