provider "aws" {
 region = "us-east-1"
}

module "vpc" {
 source = "terraform-aws-modules/vpc/aws"

 name = "my-vpc"
 cidr = "10.0.0.0/16"

 azs            = ["us-east-1a", "us-east-1b"]
 private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
 public_subnets = ["10.0.3.0/24", "10.0.4.0/24"]

 enable_nat_gateway = true

 tags = {
   Terraform  = "true"
   Environment = "dev"
 }
}

module "eks" {
 source = "terraform-aws-modules/eks/aws"

 cluster_name   = "my-eks-cluster"
 cluster_version = "1.28"
 vpc_id         = module.vpc.vpc_id

 tags = {
   Terraform  = "true"
   Environment = "dev"
 }
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy_attachment" {
 role      = "arn:aws:iam::101478099523:role/deploy_lambda_dynamo"
 policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "eks_service_policy_attachment" {
 role      = "arn:aws:iam::101478099523:role/deploy_lambda_dynamo"
 policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
}

resource "aws_eks_fargate_profile" "my_fargate_profile" {
 cluster_name          = module.eks.cluster_name
 fargate_profile_name  = "my-fargate-profile"
 pod_execution_role_arn = module.eks.fargate_execution_role_arn
 subnet_ids            = module.vpc.private_subnets

 selector {
   namespace = "default"
 }
}