module "aks" {
  source         = "../../../../modules/aks"
  resource_group = var.resource_group
  location       = var.location
  cluster_name   = var.cluster_name
}
