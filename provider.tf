provider "aws" {
  region  = "eu-central-1"
  profile = "opsfleet-demo"
  default_tags {
    tags = {
      Business-meaningful = "opsfleet-demo"
      ManagedBy           = "Terraform"
    }
  }
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    #args        = ["token", "-i", module.eks.cluster_name]
    args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
    env = {
      name : "AWS_PROFILE"
      value : "opsfleet-demo"
    }
  }
}
