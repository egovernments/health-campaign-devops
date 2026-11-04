output "resource_group" {
  value = azurerm_resource_group.rg.name
}

output "location" {
  value = azurerm_resource_group.rg.location
}

output "cluster_name" {
  value = azurerm_kubernetes_cluster.aks.name
}

output "postgres_server_name" {
  value = azurerm_postgresql_flexible_server.postgresql_server.name
}

output "postgres_fqdn" {
  value = azurerm_postgresql_flexible_server.postgresql_server.fqdn
}

output "postgres_database_name" {
  value = azurerm_postgresql_flexible_server_database.db.name
}

output "db_user" {
  value = var.db_user
}

output "filestore_account_name" {
  value = azurerm_storage_account.filestore.name
}

output "key_vault_name" {
  value = azurerm_key_vault.kv.name
}

output "nat_public_ip" {
  description = "Static egress IP — allowlist this wherever hcm-demo's egress IP is allowlisted."
  value       = azurerm_public_ip.public_ip.ip_address
}

output "sops_key_url" {
  description = "Versioned key URL the v2 environment's SOPS secrets are encrypted against."
  value       = azurerm_key_vault_key.sops.id
}
