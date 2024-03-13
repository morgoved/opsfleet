terraform {
  required_version = "~> 1.4.6" # terraform://version
  backend "s3" {
    bucket               = "opsfleet-terraform-states"
    dynamodb_table       = "opsfleet-terraform-states-lock"
    encrypt              = true
    key                  = "opsfleet-demo/terraform.tfstate"
    region               = "eu-central-1"
    workspace_key_prefix = "env"
    profile              = "opsfleet-demo"
  }
}
