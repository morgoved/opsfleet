module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.0"

  name = local.name
  cidr = local.vpc_cidr

  azs             = local.azs
  private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 4, k)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 48)]
  intra_subnets   = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 52)]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  enable_flow_log                      = true
  create_flow_log_cloudwatch_iam_role  = true
  create_flow_log_cloudwatch_log_group = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }

  tags = local.tags
}

data "aws_availability_zones" "available" {}
data "aws_caller_identity" "current" {}

resource "aws_security_group" "additional" {
  name_prefix = "${local.name}-additional"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = [
      "10.0.0.0/8",
      "172.16.0.0/12",
      "192.168.0.0/16",
    ]
  }

  ingress {
    from_port = 4443
    to_port   = 4443
    protocol  = "tcp"
    cidr_blocks = [
      "10.0.0.0/8",
      "172.16.0.0/12",
      "192.168.0.0/16",
    ]
  }

  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    cidr_blocks = [
      "10.0.0.0/8",
      "172.16.0.0/12",
      "192.168.0.0/16",
    ]
  }

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    cidr_blocks = [
      "10.0.0.0/8",
      "172.16.0.0/12",
      "192.168.0.0/16",
    ]
  }
  ingress {
    from_port = 2049
    to_port = 2049
    protocol = "tcp"
    cidr_blocks = [
      "10.0.0.0/8",
      "172.16.0.0/12",
      "192.168.0.0/16",
    ]
  }

  // Terraform removes the default rule
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [
      "10.0.0.0/8",
      "172.16.0.0/12",
      "192.168.0.0/16",
    ]
  }

  tags = merge(local.tags, { Name = "${local.name}-additional" })
}

resource "aws_iam_policy" "additional" {
  name = "${local.name}-additional"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:Describe*",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

module "kms" {
  source  = "terraform-aws-modules/kms/aws"
  version = "1.1.0"

  aliases               = ["eks/${local.name}"]
  description           = "${local.name} cluster encryption key"
  enable_default_policy = true
  key_owners            = [data.aws_caller_identity.current.arn]

  tags = local.tags
}


module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = local.name
  cluster_version = "1.29"

  cluster_endpoint_public_access  = true

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    aws-ebs-csi-driver = {
      most_recent = true
    }
  }

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.intra_subnets
  # Extend cluster security group rules
  cluster_security_group_additional_rules = {
    ingress_nodes_ephemeral_ports_tcp = {
      description                = "Nodes on ephemeral ports"
      protocol                   = "tcp"
      from_port                  = 1
      to_port                    = 65535
      type                       = "ingress"
      source_node_security_group = true
    }
    ingress_efs_ports_tcp = {
      description                = "efs allow"
      protocol                   = "tcp"
      from_port                  = 2049
      to_port                    = 2049
      type                       = "ingress"
      source_node_security_group = true
    }
    egress_tcp = {
      description                = "efs allow for all"
      protocol                   = "tcp"
      from_port                  = 1
      to_port                    = 65535
      type                       = "ingress"
      source_node_security_group = true
    }
    egress_tcp = {
      description                = "egres allow"
      protocol                   = "-1"
      from_port                  = 0
      to_port                    = 0
      type                       = "egress"
      source_node_security_group = true
    }
    # Test: https://github.com/terraform-aws-modules/terraform-aws-eks/pull/2319
    ingress_source_security_group_id = {
      description              = "Ingress from another computed security group"
      protocol                 = "tcp"
      from_port                = 2222
      to_port                  = 2222
      type                     = "ingress"
      source_security_group_id = aws_security_group.additional.id
    }

  }

  # Extend node-to-node security group rules
  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
    # Test: https://github.com/terraform-aws-modules/terraform-aws-eks/pull/2319
    ingress_source_security_group_id = {
      description              = "Ingress from another computed security group"
      protocol                 = "tcp"
      from_port                = 22
      to_port                  = 22
      type                     = "ingress"
      source_security_group_id = aws_security_group.additional.id
    }
  }
  # EKS Managed Node Group(s)
  eks_managed_node_groups = {
    green = {
      min_size     = 3
      max_size     = 3
      desired_size = 3
      instance_types = ["c5a.xlarge"]
    }
  }

  # aws-auth configmap
  create_aws_auth_configmap = false
  manage_aws_auth_configmap = false

  aws_auth_roles = [
    {
      rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.account.role}"
      username = "k8s"
      groups   = ["system:masters"]
    },
  ]

  aws_auth_users = [
    {
      userarn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/${local.account.user}"
      username = "k8s"
      groups   = ["system:masters"]
    },
  ]

  aws_auth_accounts = [
    "${data.aws_caller_identity.current.account_id}",
  ]

  tags = local.tags
}

data "aws_partition" "current" {}

resource "aws_iam_role" "s3-role" {
  name = "s3-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

module "s3" {
  source = "./s3"
  buckets = {
    opsfleet-demo = {
      tags = {
        Business-meaningful = "opsfleet-demo"
        ManagedBy = "Terraform"
      }
      custom-policy = {}
      roles_attach_access_rw = [
        "s3-role"]
      roles_attach_access_ro = []
      addon = {
        acl = {}
        lifecycle_rules = [
          {
            id = "delete-old"
            abort_incomplete_multipart_upload_days = 10
            filter = {}
            status = "Enabled"
            expiration = {
              days = 90
            }
          }
        ]
      }
    }
  }
}

resource "aws_iam_role" "service_account" {
  for_each             = local.service_account_roles
  description          = "Role to be used by ${each.key} app in ${each.value.project} ${each.value.env} stack"
  max_session_duration = each.value.max_session_duration
  name                 = "${local.name}-${each.key}"
  path                 = "/"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Federated" : "${module.eks.oidc_provider_arn}"
        },
        "Action" : "sts:AssumeRoleWithWebIdentity",
        "Condition" : {
          "StringEquals" : {
            "${split("oidc-provider/", module.eks.oidc_provider_arn)[1]}:aud" : "sts.amazonaws.com",
            "${split("oidc-provider/", module.eks.oidc_provider_arn)[1]}:sub" : "system:serviceaccount:${each.value.namespace}:${lookup(each.value, "service_account", each.key)}"
          }
        }
      }
    ]
  })
}

module "roles_attach" {
  for_each                    = local.service_account_roles
  source                      = "./policy_attach"
  service_account_policy_arns = each.value.policy_arns
  role                        = aws_iam_role.service_account[each.key].name
}
