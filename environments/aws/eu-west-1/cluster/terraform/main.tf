module "eks" {
  source       = "../../../../modules/eks"
  region       = var.region
  cluster_name = var.cluster_name
}
