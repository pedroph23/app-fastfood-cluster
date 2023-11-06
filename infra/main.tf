provider "aws" {
 region = "us-east-1"
}

module "vpc" {
 source = "terraform-aws-modules/vpc/aws"
 

 name = "my-vpc"
 cidr = "10.0.0.0/16"

 azs           = ["us-east-1a", "us-east-1b"]
 private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
 public_subnets = ["10.0.3.0/24", "10.0.4.0/24"]

 enable_nat_gateway = true
}

module "eks" {
 source = "terraform-aws-modules/eks/aws"
 version = "19.0.0"
 cluster_name  = "my-eks-cluster"
 cluster_version = "1.28"
 vpc_id        = module.vpc.vpc_id

 control_plane_subnet_ids = module.vpc.private_subnets
 subnet_ids              = module.vpc.private_subnets
 create_kms_key = false
}

resource "aws_iam_role" "fargate_role" {
 name = "eks-fargate-role"

 assume_role_policy = jsonencode({
  Version = "2012-10-17"
  Statement = [
    {
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks-fargate-pods.amazonaws.com"
      }
    },
  ]
 })
}

resource "aws_iam_role_policy_attachment" "fargate_policy_attachment" {
 role      = aws_iam_role.fargate_role.name
 policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy_attachment" {
 role      = "deploy_lambda_dynamo"
 policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "eks_service_policy_attachment" {
 role      = "deploy_lambda_dynamo"
 policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
}

resource "aws_eks_fargate_profile" "my_fargate_profile" {
 cluster_name         = module.eks.cluster_name
 fargate_profile_name = "my-fargate-profile"
 pod_execution_role_arn = aws_iam_role.fargate_role.arn
 subnet_ids           = module.vpc.private_subnets

 selector {
  namespace = "default"
 }
}
