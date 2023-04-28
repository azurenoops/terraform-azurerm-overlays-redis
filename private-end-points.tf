# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

#---------------------------------------------------------
# Private Link for Sql - Default is "false" 
#---------------------------------------------------------

resource "azurerm_private_endpoint" "pep" {
  count               = var.enable_private_endpoint ? 1 : 0
  name                = format("%s-private-endpoint", local.redis_name)
  location            = var.location
  resource_group_name = local.resource_group_name
  subnet_id           = data.azurerm_subnet.existing_snet.0.id
  tags                = merge({ "Name" = format("%s-private-endpoint", local.redis_name) }, var.add_tags, )

  private_service_connection {
    name                           = "rediscache-privatelink"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_redis_cache.redis.id
    subresource_names              = ["redisCache"]
  }
}

#------------------------------------------------------------------
# DNS zone & records for Private networking - Default is "false" 
#------------------------------------------------------------------
resource "azurerm_private_dns_zone" "dns_zone" {
  count               = var.existing_private_dns_zone == null && (var.existing_subnet_name != null || var.enable_private_endpoint) ? 1 : 0
  name                = var.environment == "public" ? "privatelink.redis.cache.windows.net" : "privatelink.redis.cache.usgovcloudapi.net"
  resource_group_name = local.resource_group_name
  tags                = merge({ "Name" = format("%s", "Azure-Redis-Cache-Private-DNS-Zone") }, var.add_tags, )
}

resource "azurerm_private_dns_zone_virtual_network_link" "vnet_link" {
  count                 = var.existing_private_dns_zone == null && (var.existing_subnet_name != null || var.enable_private_endpoint)  ? 1 : 0
  name                  = "vnet-private-zone-link"
  resource_group_name   = local.resource_group_name
  private_dns_zone_name = var.existing_private_dns_zone == null ? azurerm_private_dns_zone.dns_zone.0.name : var.existing_private_dns_zone
  virtual_network_id    = data.azurerm_virtual_network.vnet.0.id
  registration_enabled  = var.allow_auto_registration
  tags                  = merge({ "Name" = format("%s", "vnet-private-zone-link") }, var.add_tags, )
}

resource "azurerm_private_dns_a_record" "a_rec" {
  depends_on = [
    azurerm_private_dns_zone.dns_zone
  ]
  count               = var.enable_private_endpoint  ? 1 : 0
  name                = lower(azurerm_redis_cache.redis.name)
  zone_name           = azurerm_private_dns_zone.dns_zone.0.name
  resource_group_name = local.resource_group_name
  ttl                 = 300
  records             = [data.azurerm_private_endpoint_connection.pip.0.private_service_connection.0.private_ip_address]
}

resource "azurerm_private_dns_a_record" "a_rec_redis" {
  count               = var.existing_subnet_name != null || var.enable_private_endpoint ? 1 : 0
  name                = lower(azurerm_redis_cache.redis.name)
  zone_name           = azurerm_private_dns_zone.dns_zone.0.name
  resource_group_name = local.resource_group_name
  ttl                 = 300
  records             = [data.azurerm_redis_cache.redis.private_static_ip_address]
}