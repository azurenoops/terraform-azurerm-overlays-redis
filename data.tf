
data "azurerm_redis_cache" "redis" {
  depends_on = [
    azurerm_redis_cache.redis
  ]
  name                = local.redis_name
  resource_group_name = local.resource_group_name
}

data "azurerm_subnet" "existing_snet" {
  count                = var.existing_subnet_name != null ? 1 : 0
  name                 = var.existing_subnet_name
  virtual_network_name = var.virtual_network_name
  resource_group_name  = local.resource_group_name
}
