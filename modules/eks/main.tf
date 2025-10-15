resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  role_arn = "arn:aws:iam::<account-id>:role/<eks-role>"
  version  = "1.30"
  vpc_config {
    subnet_ids = ["subnet-xxxxxxxx", "subnet-yyyyyyyy"]
  }
}

resource "aws_eks_node_group" "default" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "default"
  node_role_arn   = "arn:aws:iam::<account-id>:role/<node-role>"
  subnet_ids      = ["subnet-xxxxxxxx", "subnet-yyyyyyyy"]
  scaling_config  { desired_size = 3, max_size = 6, min_size = 3 }
}
