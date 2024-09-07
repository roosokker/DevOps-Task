locals {
    cluster_name = "EKS-Cluster"
}

resource "aws_eks_cluster" "EKSCluster" {
  name     = local.cluster_name
  role_arn = aws_iam_role.eks_role.arn

  vpc_config {
    subnet_ids =  concat(module.vpc.private_subnets, module.vpc.public_subnets)
  }

  enabled_cluster_log_types = ["api", "audit"]

  depends_on = [
    aws_iam_role_policy_attachment.EKSClusterPolicy,
    aws_cloudwatch_log_group.eks_log_group
  ]
}

data "aws_ssm_parameter" "eks_ami_release_version" {
  name = "/aws/service/eks/optimized-ami/${aws_eks_cluster.EKSCluster.version}/amazon-linux-2/recommended/release_version"
}

resource "aws_eks_node_group" "eks_cluster_node" {
  cluster_name    = aws_eks_cluster.EKSCluster.name
  node_group_name = "eks-cluster-nodes"
  node_role_arn   = aws_iam_role.eks_node_group_role.arn
  subnet_ids      = concat(module.vpc.private_subnets, module.vpc.public_subnets)
  version         = aws_eks_cluster.EKSCluster.version
  release_version = nonsensitive(data.aws_ssm_parameter.eks_ami_release_version.value)

  scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.localAmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.localAmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.localAmazonEC2ContainerRegistryReadOnly,
  ]
}

resource "aws_iam_role" "eks_node_group_role" {
  name = "eks-node-group-role"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "localAmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_group_role.name
}

resource "aws_iam_role_policy_attachment" "localAmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_group_role.name
}

resource "aws_iam_role_policy_attachment" "localAmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_group_role.name
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "eks_role" {
  name               = "${local.cluster_name}-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "EKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_role.name
}

resource "aws_cloudwatch_log_group" "eks_log_group" {
  name              = "/aws/eks/${local.cluster_name}/cluster"
  retention_in_days = 7
}
