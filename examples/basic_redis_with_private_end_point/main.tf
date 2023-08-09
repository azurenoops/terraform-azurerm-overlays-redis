
resource "random_id" "prefix" {
  byte_length = 8
}

module "mod_redis" {
  depends_on = [
    azurerm_resource_group.redis_rg,
    azurerm_virtual_network.redis_vnet,
    azurerm_subnet.redis_subnet,
    azurerm_subnet.redis_pe_subnet,
  ]
  source = "../.."

  # By default, this module will create a resource group and 
  # provide a name for an existing resource group. If you wish 
  # to use an existing resource group, change the option 
  # to "create_redis_resource_group = false." The location of the group 
  # will remain the same if you use the current resource.
  existing_resource_group_name = azurerm_resource_group.redis_rg.name
  location                     = module.mod_azure_region_lookup.location_cli
  environment                  = "public"
  deploy_environment           = "dev"
  org_name                     = "anoa"
  workload_name                = "cache-test"

  # Configuration to provision a Standard Redis Cache
  # Specify `shared_count` to create on the Redis Cluster
  cluster_shard_count = 3

  # MEMORY MANAGEMENT
  # Azure Cache for Redis instances are configured with the following default Redis configuration values:
  redis_configuration = {
    maxmemory_reserved = 2
    maxmemory_delta    = 2
    maxmemory_policy   = "allkeys-lru"
  }

  # Nodes are patched one at a time to prevent data loss. Basic caches will have data loss.
  # Clustered caches are patched one shard at a time. 
  # The Patch Window lasts for 5 hours from the `start_hour_utc`
  patch_schedules = [
    {
      day_of_week    = "Saturday"
      start_hour_utc = 10
    }
  ]

  # Creating Private Endpoint requires, VNet name to create a Private Endpoint
  # By default this will create a `privatelink.redis.cache.windows.net` DNS zone. if created in commercial cloud
  # To use existing subnet, specify `existing_subnet_id` with valid subnet id. 
  # To use existing private DNS zone specify `existing_private_dns_zone` with valid zone name
  # Private endpoints doesn't work If not using `existing_subnet_id` to create redis inside a specified VNet.
  enable_private_endpoint      = true
  existing_private_subnet_name = azurerm_subnet.redis_pe_subnet.name
  virtual_network_name         = azurerm_virtual_network.redis_vnet.name

  # Tags for Azure Resources
  add_tags = local.tags # Tags to be applied to all resources
}
