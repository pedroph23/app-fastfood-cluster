provider "aws" {
  region = "us-east-1" # Substitua pela sua região preferida
}

resource "aws_eks_cluster" "my_cluster" {
  name     = "my-eks-cluster"
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids = aws_subnet.my_subnets[].id
  }
}

resource "aws_iam_role" "eks_cluster_role" {
  name = "eks-cluster-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_subnet" "my_subnets" {
  count = 2

  vpc_id                  = aws_vpc.my_vpc.id
  availability_zone       = element(["us-west-2a", "us-west-2b"], count.index)
  cidr_block              = element(["10.0.1.0/24", "10.0.2.0/24"], count.index)
  map_public_ip_on_launch = true
}

resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_eks_fargate_profile" "my_fargate_profile" {
  cluster_name = aws_eks_cluster.my_cluster.name
  fargate_profile_name = "my-fargate-profile"
  pod_execution_role_arn = aws_iam_role.fargate_execution_role.arn
  subnet_ids = aws_subnet.my_subnets[].id

  selector {
    namespace = "default" # Namespace do Kubernetes
  }
}

resource "aws_iam_role" "fargate_execution_role" {
  name = "eks-fargate-execution-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks-fargate-pods.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}