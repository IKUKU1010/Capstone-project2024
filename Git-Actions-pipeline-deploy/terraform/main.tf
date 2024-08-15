provider "aws" {
  region = "us-east-1"
}

data "aws_ami" "latest-ubuntu-jammy-22-04-image" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

resource "aws_launch_template" "eks" {
  name_prefix   = "eks-"
  image_id      = data.aws_ami.latest-ubuntu-jammy-22-04-image.id
  instance_type = "t3.medium"

  lifecycle {
    create_before_destroy = true
  }
}

module "vpc" {
  source = "git::https://github.com/IKUKU1010/terraform-aws-vpc.git?ref=master"

  name              = "socks-shop-vpc"
  cidr              = "10.0.0.0/16"
  azs               = ["us-east-1a", "us-east-1c"]
  public_subnets    = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets   = ["10.0.3.0/24", "10.0.4.0/24"]
  enable_nat_gateway  = true
  single_nat_gateway  = true
  enable_dns_hostnames = true
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "socks-shop-CICD001"
  cluster_version = "1.30"
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.private_subnets

  cluster_endpoint_public_access = true

  eks_managed_node_groups = {
    work-node1 = {
      name           = "sockapp-node1"
      launch_template = {
        id      = aws_launch_template.eks.id
        version = "$Latest"
      }
      instance_types = ["t3.medium"]
      min_size       = 1
      max_size       = 2
      desired_size   = 2
    }

    work-node2 = {
      name           = "sockapp-node2"
      launch_template = {
        id      = aws_launch_template.eks.id
        version = "$Latest"
      }
      instance_types = ["t3.medium"]
      min_size       = 1
      max_size       = 2
      desired_size   = 2
    }
  }

  enable_cluster_creator_admin_permissions = true
}