
resource "random_id" "prefix" {
  byte_length = 8
}

#---------------------------------------------------------
# Azure Region Lookup
#----------------------------------------------------------
module "mod_azure_region_lookup" {
  source  = "azurenoops/overlays-azregions-lookup/azurerm"
  version = "~> 1.0.0"

  azure_region = "eastus"
}

#---------------------------------------------------------
# Resource Group Creation
#----------------------------------------------------------
module "mod_redis_rg" {
  source  = "azurenoops/overlays-resource-group/azurerm"
  version = "~> 1.0.1"

  location                = module.mod_azure_region_lookup.location_cli
  use_location_short_name = true # Use the short location name in the resource group name
  org_name                = "anoa"
  environment             = "dev"
  workload_name           = "dev-cache-test"
  custom_rg_name          = null

  // Tags
  add_tags = merge({}, {
    DeployedBy = format("AzureNoOpsTF [%s]", terraform.workspace)
  }) # Tags to be applied to all resources
}

resource "azurerm_virtual_network" "test" {
  address_space       = ["10.52.0.0/16"]
  location            = module.mod_redis_rg.resource_group_location
  name                = "${random_id.prefix.hex}-vnet"
  resource_group_name = module.mod_redis_rg.resource_group_name
}

resource "azurerm_subnet" "test" {
  address_prefixes                          = ["10.52.0.0/24"]
  name                                      = "${random_id.prefix.hex}-snet"
  resource_group_name                       = module.mod_redis_rg.resource_group_name
  virtual_network_name                      = azurerm_virtual_network.test.name
  private_endpoint_network_policies_enabled = true
}

module "mod_redis" {
  depends_on = [
    module.mod_redis_rg
  ]
  source = "../.."

  # By default, this module will create a resource group and 
  # provide a name for an existing resource group. If you wish 
  # to use an existing resource group, change the option 
  # to "create_redis_resource_group = false." The location of the group 
  # will remain the same if you use the current resource.
  create_redis_resource_group = false
  custom_resource_group_name  = module.mod_redis_rg.resource_group_name
  location                    = module.mod_redis_rg.resource_group_location
  environment                 = "public"
  deploy_environment          = "dev"
  org_name                    = "anoa"
  workload_name               = "dev-cache-test"

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
  enable_private_endpoint = true
  existing_subnet_id      = azurerm_subnet.test.id
  virtual_network_name    = azurerm_virtual_network.test.name
  #  existing_private_dns_zone     = "demo.example.com"

  # Tags for Azure Resources
  add_tags = merge({}, {
    DeployedBy = format("AzureNoOpsTF [%s]", terraform.workspace)
  }) # Tags to be applied to all resources
}
