output "cluster_name" { value = aws_eks_cluster.this.name }
output "kubeconfig"   { value = "aws eks update-kubeconfig --region ${var.region} --name ${aws_eks_cluster.this.name}" }
