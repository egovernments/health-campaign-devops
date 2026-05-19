output "resource_group"{
  value = var.resource_group
}

output "cluster_name" {
  value = var.environment
}

output "db_instance_endpoint" {
  value = module.postgres-db.azurerm_postgresql_flexible_server
}

output "db_instance_name" {
  value = module.postgres-db.postgresql_flexible_server_database_name
}

output "db_user" {
  value = var.db_user
}