provider "aws" {
  region = "us-east-1"  # Substitua pela sua região preferida
}


resource "aws_iam_role" "eks_cluster_role" {
  name = "eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "control_plane_subnets" {
  count = 2

  vpc_id                  = aws_vpc.my_vpc.id
  availability_zone       = element(["us-east-1a", "us-east-1b"], count.index)
  cidr_block              = element(["10.0.1.0/24", "10.0.2.0/24"], count.index)
}

resource "aws_subnet" "fargate_subnets" {
  count = 2

  vpc_id                  = aws_vpc.my_vpc.id
  availability_zone       = element(["us-east-1a", "us-east-1b"], count.index)
  cidr_block              = element(["10.0.3.0/24", "10.0.4.0/24"], count.index)
}


module "eks" {
  source = "terraform-aws-modules/eks/aws"
  manage_aws_auth_configmap = true
  aws_auth_users            = ["arn:aws:iam::101478099523:root"]

  cluster_name    = "my-eks-cluster"
  cluster_version = "1.28"
  vpc_id          = aws_vpc.my_vpc.id
  control_plane_subnet_ids = aws_subnet.control_plane_subnets[*].id
  subnet_ids = aws_subnet.fargate_subnets[*].id

  tags = {
    Terraform   = "true"
    Environment = "prod"
  }
}

resource "aws_eks_fargate_profile" "my_fargate_profile" {
  cluster_name            = module.eks.cluster_name
  fargate_profile_name    = "my-fargate-profile"
  pod_execution_role_arn  = aws_iam_role.fargate_execution_role.arn
  subnet_ids              = aws_subnet.fargate_subnets[*].id

  selector {
    namespace = "default"  # Substitua pelo namespace Kubernetes desejado
  }
}

resource "aws_iam_role" "fargate_execution_role" {
  name = "eks-fargate-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "eks-fargate-pods.amazonaws.com"
        }
      }
    ]
  })
}
