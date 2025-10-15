resource "azurerm_kubernetes_cluster" "this" {
  name                = var.cluster_name
  location            = var.location
  resource_group_name = var.resource_group
  dns_prefix          = "ha-aks"
  default_node_pool {
    name       = "default"
    node_count = 3
    vm_size    = "Standard_D4s_v5"
  }
  identity { type = "SystemAssigned" }
}
