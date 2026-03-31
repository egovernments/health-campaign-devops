output "aks_principal_id" {
  value       = azurerm_kubernetes_cluster.aks.identity[0].principal_id
  description = "The principal ID of the AKS cluster's managed identity"
}

output "cluster_name" {
  value       = azurerm_kubernetes_cluster.aks.name
  description = "The name of the AKS cluster"
}

output "kube_config" {
  value       = azurerm_kubernetes_cluster.aks.kube_config_raw
  sensitive   = true
  description = "Kubernetes config for kubectl access"
}