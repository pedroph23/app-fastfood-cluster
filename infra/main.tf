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

resource "aws_security_group" "ssh_cluster" {
  name        = "ssh_cluster"
  vpc_id      = module.vpc.vpc_id
}

resource "aws_security_group_rule" "ssh_cluster_in" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"] #0.0.0.0 - 255.255.255.255
  security_group_id = aws_security_group.ssh_cluster.id
}

resource "aws_security_group_rule" "ssh_cluster_out" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"] #0.0.0.0 - 255.255.255.255
  security_group_id = aws_security_group.ssh_cluster.id
}

module "eks" {
 source = "terraform-aws-modules/eks/aws"
 version = "19.0.0"
 cluster_name  = "my-eks-cluster"
 cluster_version = "1.28"
  cluster_endpoint_private_access = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {
    alura = {
      min_size     = 1
      max_size     = 10
      desired_size = 3
      vpc_security_group_ids = [aws_security_group.ssh_cluster.id]
      instance_types = ["t2.micro"]
    }
  }
}


resource "aws_iam_role_policy_attachment" "eks_cluster_policy_attachment" {
 role      = "deploy_lambda_dynamo"
 policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "eks_service_policy_attachment" {
 role      = "deploy_lambda_dynamo"
 policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
}


resource "aws_iam_role_policy" "eks_nodegroup_policy" {
  name = "eks_nodegroup_policy"
  role = "deploy_lambda_dynamo"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "eks:*",
      "Resource": "arn:aws:eks:us-east-1:101478099523:cluster/my-eks-cluster"
    }
  ]
}
EOF
}

