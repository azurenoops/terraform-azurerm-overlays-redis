data "azurerm_virtual_network" "vnet" {
  count               = local.is_subnet_injected == null ? 1 : 0
  name                = var.virtual_network_name
  resource_group_name = local.resource_group_name
}

data "azurerm_subnet" "existing_snet" {
  count               = local.is_subnet_injected ? 1 : 0
  name                = var.existing_subnet_name
  virtual_network_name = var.virtual_network_name
  resource_group_name = local.resource_group_name
}

data "azurerm_private_endpoint_connection" "pip" {
  count               = var.enable_private_endpoint ? 1 : 0
  name                = azurerm_private_endpoint.pep.0.name
  resource_group_name = local.resource_group_name
  depends_on          = [azurerm_redis_cache.redis]
}
