locals {
  name   = "opsfleet-demo"
  region = "eu-central-1"

  vpc_cidr = "10.0.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)
  account = {
    role = "opsfleet-demo-role"
    user = "opsfleet-demo-user"
  }

  tags = {
    eksname    = local.name
    Business-meaningful = "opsfleet-demo"
    ManagedBy           = "Terraform"
  }
  service_account_roles = {
    pg-dump-bk = {
      max_session_duration = 3600
      namespace = "prod"
      project = "prod"
      env = "prod"
      policy_arns = [
        module.s3.policy_rw.opsfleet-demo
      ]
    }
  }
}
