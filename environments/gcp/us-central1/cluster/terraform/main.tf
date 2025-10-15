module "gke" {
  source       = "../../../../modules/gke"
  project      = var.project
  region       = var.region
  cluster_name = var.cluster_name
}
