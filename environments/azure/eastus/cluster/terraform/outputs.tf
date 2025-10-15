output "cluster_name" { value = azurerm_kubernetes_cluster.this.name }
output "kubeconfig"   { value = "az aks get-credentials --resource-group ${var.resource_group} --name ${azurerm_kubernetes_cluster.this.name}" }
