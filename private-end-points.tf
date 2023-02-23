# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

#---------------------------------------------------------
# Private Link for Redis Server - Default is "false" 
#---------------------------------------------------------
data "azurerm_virtual_network" "redis_vnet" {
  count               = var.enable_private_endpoint ? 1 : 0
  name                = var.virtual_network_name
  resource_group_name = local.resource_group_name
}

resource "azurerm_private_endpoint" "redis_pep" {
  depends_on          = [azurerm_redis_cache.redis]
  count               = var.enable_private_endpoint ? 1 : 0
  name                = format("%s-private-endpoint", element([azurerm_redis_cache.redis.name], 0))
  location            = module.mod_azure_region_lookup.location_cli
  resource_group_name = local.resource_group_name
  subnet_id           = var.existing_subnet_id
  tags                = merge({ "Name" = format("%s-private-endpoint", element([azurerm_redis_cache.redis.name], 0)) }, var.add_tags, )

  private_service_connection {
    name                           = "rediscache-privatelink"
    is_manual_connection           = false
    private_connection_resource_id = element([azurerm_redis_cache.redis.id], 0)
    subresource_names              = ["redisCache"]
  }
}

data "azurerm_private_endpoint_connection" "redis_private_ip" {
  count               = var.enable_private_endpoint ? 1 : 0
  name                = azurerm_private_endpoint.redis_pep.0.name
  resource_group_name = local.resource_group_name
  depends_on          = [azurerm_redis_cache.redis]
}

resource "azurerm_private_dns_zone" "redis_dnszone" {
  count               = var.existing_private_dns_zone == null && var.enable_private_endpoint ? 1 : 0
  name                = var.environment == "public" ? "privatelink.redis.cache.windows.net" : "privatelink.redis.cache.usgovcloudapi.net"
  resource_group_name = local.resource_group_name
  tags                = merge({ "Name" = format("%s", "RedisCache-Private-DNS-Zone") }, var.add_tags, )
}

resource "azurerm_private_dns_zone_virtual_network_link" "redis_vnet_link" {
  count                 = var.existing_private_dns_zone == null && var.enable_private_endpoint ? 1 : 0
  name                  = "vnet-private-zone-link"
  resource_group_name   = local.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.redis_dnszone.0.name
  virtual_network_id    = data.azurerm_virtual_network.redis_vnet.0.id
  tags                  = merge({ "Name" = format("%s", "vnet-private-zone-link") }, var.add_tags, )
}

resource "azurerm_private_dns_a_record" "arecord_redis" {
  count               = var.enable_private_endpoint ? 1 : 0
  name                = element([azurerm_redis_cache.redis.name], 0)
  zone_name           = var.existing_private_dns_zone == null ? azurerm_private_dns_zone.redis_dnszone.0.name : var.existing_private_dns_zone
  resource_group_name = local.resource_group_name
  ttl                 = 300
  records             = [data.azurerm_private_endpoint_connection.redis_private_ip.0.private_service_connection.0.private_ip_address]
}