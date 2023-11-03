provider "aws" {
  region = "us-east-1"  # Substitua pela sua região preferida
}

resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_eks_cluster" "my_cluster" {
  name     = "my-eks-cluster"
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids = aws_subnet.my_subnets[*].id
  }
}

resource "aws_subnet" "my_subnets" {
  count = 2

  vpc_id                  = aws_vpc.my_vpc.id
  availability_zone       = element(["us-east-1a", "us-east-1b"], count.index)  # Substitua as zonas de disponibilidade
  cidr_block              = element(["10.0.1.0/24", "10.0.2.0/24"], count.index)
  map_public_ip_on_launch = true
}

resource "aws_iam_role" "eks_cluster_role_1" {
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

resource "aws_eks_fargate_profile" "my_fargate_profile" {
  cluster_name            = aws_eks_cluster.my_cluster.name
  fargate_profile_name    = "my-fargate-profile"
  pod_execution_role_arn  = aws_iam_role.fargate_execution_role.arn
  subnet_ids              = aws_subnet.my_subnets[*].id

  selector {
    namespace = "default"  # Substitua pelo namespace Kubernetes desejado
  }
}

resource "aws_iam_role" "fargate_execution_role_1" {
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
