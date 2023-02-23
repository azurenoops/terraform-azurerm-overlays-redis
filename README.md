# Azure Redis Cache Overlay

[![Changelog](https://img.shields.io/badge/changelog-release-green.svg)](CHANGELOG.md) [![MIT License](https://img.shields.io/badge/license-MIT-orange.svg)](LICENSE) [![TF Registry](https://img.shields.io/badge/terraform-registry-blue.svg)](https://registry.terraform.io/modules/azurenoops/overlays-redis/azurerm/)

This Overlay terraform module can create a Redis Cache and manage related parameters (Threat protection, Redis Cache FW Rules, Private Endpoints, etc.) to be used in a [SCCA compliant Network](https://registry.terraform.io/modules/azurenoops/overlays-hubspoke/azurerm/latest).

## SCCA Compliance

This module can be SCCA compliant and can be used in a SCCA compliant Network. Enable private endpoints and SCCA compliant network rules to make it SCCA compliant.

For more information, please read the [SCCA documentation]("https://www.cisa.gov/secure-cloud-computing-architecture").

## Contributing

If you want to contribute to this repository, feel free to to contribute to our Terraform module.

More details are available in the [CONTRIBUTING.md](./CONTRIBUTING.md#pull-request-process) file.

## Usage

```hcl
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
  source  = "azurenoops/overlays-redis/azurerm"
  version = "~> 1.0.0"

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

```

<!-- BEGIN_TF_DOCS -->
| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3 |
| <a name="requirement_azurenoopsutils"></a> [azurenoopsutils](#requirement\_azurenoopsutils) | ~> 1.0.4 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 3.22 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurenoopsutils"></a> [azurenoopsutils](#provider\_azurenoopsutils) | ~> 1.0.4 |
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | ~> 3.22 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_mod_azure_region_lookup"></a> [mod\_azure\_region\_lookup](#module\_mod\_azure\_region\_lookup) | azurenoops/overlays-azregions-lookup/azurerm | ~> 1.0.0 |
| <a name="module_mod_redis_rg"></a> [mod\_redis\_rg](#module\_mod\_redis\_rg) | azurenoops/overlays-resource-group/azurerm | ~> 1.0.1 |

## Resources

| Name | Type |
|------|------|
| [azurerm_management_lock.redis_level_lock](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/management_lock) | resource |
| [azurerm_management_lock.storage_account_level_lock](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/management_lock) | resource |
| [azurerm_private_dns_a_record.arecord_redis](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_a_record) | resource |
| [azurerm_private_dns_zone.redis_dnszone](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone) | resource |
| [azurerm_private_dns_zone_virtual_network_link.redis_vnet_link](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone_virtual_network_link) | resource |
| [azurerm_private_endpoint.redis_pep](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint) | resource |
| [azurerm_redis_cache.redis](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/redis_cache) | resource |
| [azurerm_redis_firewall_rule.redis_fw_rule](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/redis_firewall_rule) | resource |
| [azurerm_storage_account.redis_storage](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account) | resource |
| [azurenoopsutils_resource_name.data_storage](https://registry.terraform.io/providers/azurenoops/azurenoopsutils/latest/docs/data-sources/resource_name) | data source |
| [azurenoopsutils_resource_name.redis](https://registry.terraform.io/providers/azurenoops/azurenoopsutils/latest/docs/data-sources/resource_name) | data source |
| [azurenoopsutils_resource_name.redis_fw_rule](https://registry.terraform.io/providers/azurenoops/azurenoopsutils/latest/docs/data-sources/resource_name) | data source |
| [azurerm_private_endpoint_connection.redis_private_ip](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/private_endpoint_connection) | data source |
| [azurerm_resource_group.rgrp](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group) | data source |
| [azurerm_virtual_network.redis_vnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/virtual_network) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_add_tags"></a> [add\_tags](#input\_add\_tags) | Map of custom tags. | `map(string)` | `{}` | no |
| <a name="input_allow_non_ssl_connections"></a> [allow\_non\_ssl\_connections](#input\_allow\_non\_ssl\_connections) | Activate non SSL port (6779) for Redis connection | `bool` | `false` | no |
| <a name="input_authorized_cidrs"></a> [authorized\_cidrs](#input\_authorized\_cidrs) | Map of authorized cidrs | `map(string)` | `{}` | no |
| <a name="input_capacity"></a> [capacity](#input\_capacity) | Redis size: (Basic/Standard: 1,2,3,4,5,6) (Premium: 1,2,3,4)  https://docs.microsoft.com/fr-fr/azure/redis-cache/cache-how-to-premium-clustering | `number` | `2` | no |
| <a name="input_cluster_shard_count"></a> [cluster\_shard\_count](#input\_cluster\_shard\_count) | Number of cluster shards desired | `number` | `3` | no |
| <a name="input_create_redis_resource_group"></a> [create\_redis\_resource\_group](#input\_create\_redis\_resource\_group) | Controls if the resource group should be created. If set to false, the resource group name must be provided. Default is true. | `bool` | `true` | no |
| <a name="input_custom_name"></a> [custom\_name](#input\_custom\_name) | Custom name of Redis Server | `string` | `""` | no |
| <a name="input_custom_resource_group_name"></a> [custom\_resource\_group\_name](#input\_custom\_resource\_group\_name) | The name of the resource group in which the resources will be created. If not provided, a new resource group will be created with the name 'rg-<org\_name>-<environment>-<workload\_name>' | `string` | `null` | no |
| <a name="input_data_persistence_enabled"></a> [data\_persistence\_enabled](#input\_data\_persistence\_enabled) | "true" to enable data persistence. | `bool` | `true` | no |
| <a name="input_data_persistence_frequency_in_minutes"></a> [data\_persistence\_frequency\_in\_minutes](#input\_data\_persistence\_frequency\_in\_minutes) | Data persistence snapshot frequency in minutes. | `number` | `60` | no |
| <a name="input_data_persistence_max_snapshot_count"></a> [data\_persistence\_max\_snapshot\_count](#input\_data\_persistence\_max\_snapshot\_count) | Max number of data persistence snapshots. | `number` | `null` | no |
| <a name="input_data_persistence_storage_account_replication"></a> [data\_persistence\_storage\_account\_replication](#input\_data\_persistence\_storage\_account\_replication) | Replication type for the Storage Account used for data persistence. | `string` | `"LRS"` | no |
| <a name="input_data_persistence_storage_account_tier"></a> [data\_persistence\_storage\_account\_tier](#input\_data\_persistence\_storage\_account\_tier) | Replication type for the Storage Account used for data persistence. | `string` | `"Premium"` | no |
| <a name="input_data_persistence_storage_custom_name"></a> [data\_persistence\_storage\_custom\_name](#input\_data\_persistence\_storage\_custom\_name) | Custom name for the Storage Account used for Redis data persistence. | `string` | `""` | no |
| <a name="input_default_tags_enabled"></a> [default\_tags\_enabled](#input\_default\_tags\_enabled) | Option to enable or disable default tags. | `bool` | `true` | no |
| <a name="input_deploy_environment"></a> [deploy\_environment](#input\_deploy\_environment) | The environment to deploy. It defaults to dev. | `string` | `"dev"` | no |
| <a name="input_enable_private_endpoint"></a> [enable\_private\_endpoint](#input\_enable\_private\_endpoint) | Manages a Private Endpoint to Azure database for Redis | `bool` | `false` | no |
| <a name="input_enable_resource_locks"></a> [enable\_resource\_locks](#input\_enable\_resource\_locks) | (Optional) Enable resource locks | `bool` | `false` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | The Terraform backend environment e.g. public or usgovernment | `string` | `null` | no |
| <a name="input_existing_private_dns_zone"></a> [existing\_private\_dns\_zone](#input\_existing\_private\_dns\_zone) | Name of the existing private DNS zone | `any` | `null` | no |
| <a name="input_existing_subnet_id"></a> [existing\_subnet\_id](#input\_existing\_subnet\_id) | ID of the existing subnet for the private endpoint | `any` | `null` | no |
| <a name="input_location"></a> [location](#input\_location) | The location/region to keep all your network resources. To get the list of all locations with table format from azure cli, run 'az account list-locations -o table' | `string` | n/a | yes |
| <a name="input_lock_level"></a> [lock\_level](#input\_lock\_level) | (Optional) id locks are enabled, Specifies the Level to be used for this Lock. | `string` | `"CanNotDelete"` | no |
| <a name="input_minimum_tls_version"></a> [minimum\_tls\_version](#input\_minimum\_tls\_version) | The minimum TLS version | `string` | `"1.2"` | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Optional prefix for the generated name | `string` | `""` | no |
| <a name="input_name_suffix"></a> [name\_suffix](#input\_name\_suffix) | Optional suffix for the generated name | `string` | `""` | no |
| <a name="input_org_name"></a> [org\_name](#input\_org\_name) | A name for the organization. It defaults to anoa. | `string` | `"anoa"` | no |
| <a name="input_patch_schedules"></a> [patch\_schedules](#input\_patch\_schedules) | A list of Patch Schedule, Azure Cache for Redis patch schedule is used to install important software updates in specified time window. | <pre>list(object({<br>    day_of_week        = string<br>    start_hour_utc     = optional(string)<br>    maintenance_window = optional(string)<br>  }))</pre> | `[]` | no |
| <a name="input_private_static_ip_address"></a> [private\_static\_ip\_address](#input\_private\_static\_ip\_address) | The Static IP Address to assign to the Redis Cache when hosted inside the Virtual Network. Changing this forces a new resource to be created. | `string` | `null` | no |
| <a name="input_redis_configuration"></a> [redis\_configuration](#input\_redis\_configuration) | Additional configuration for the Redis instance. Some of the keys are set automatically. See https://www.terraform.io/docs/providers/azurerm/r/redis_cache.html#redis_configuration for full reference. | <pre>object({<br>    aof_backup_enabled              = optional(bool)<br>    aof_storage_connection_string_0 = optional(string)<br>    aof_storage_connection_string_1 = optional(string)<br>    enable_authentication           = optional(bool)<br>    maxmemory_reserved              = optional(number)<br>    maxmemory_delta                 = optional(number)<br>    maxmemory_policy                = optional(string)<br>    maxfragmentationmemory_reserved = optional(number)<br>    rdb_backup_enabled              = optional(bool)<br>    rdb_backup_frequency            = optional(number)<br>    rdb_backup_max_snapshot_count   = optional(number)<br>    rdb_storage_connection_string   = optional(string)<br>    notify_keyspace_events          = optional(string)<br>  })</pre> | `{}` | no |
| <a name="input_redis_version"></a> [redis\_version](#input\_redis\_version) | Redis version to deploy. Allowed values are 4 or 6 | `number` | `6` | no |
| <a name="input_sku_name"></a> [sku\_name](#input\_sku\_name) | Redis Cache Sku name. Can be Basic, Standard or Premium | `string` | `"Premium"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to add to all resources | `map(string)` | `{}` | no |
| <a name="input_use_location_short_name"></a> [use\_location\_short\_name](#input\_use\_location\_short\_name) | Use short location name for resources naming (ie eastus -> eus). Default is true. If set to false, the full cli location name will be used. if custom naming is set, this variable will be ignored. | `bool` | `true` | no |
| <a name="input_use_naming"></a> [use\_naming](#input\_use\_naming) | Use the Azure CAF naming provider to generate default resource name. `custom_name` override this if set. Legacy default name is used if this is set to `false`. | `bool` | `true` | no |
| <a name="input_virtual_network_name"></a> [virtual\_network\_name](#input\_virtual\_network\_name) | Name of the virtual network for the private endpoint | `any` | `null` | no |
| <a name="input_workload_name"></a> [workload\_name](#input\_workload\_name) | A name for the workload. It defaults to hub-core. | `string` | `"hub-core"` | no |
| <a name="input_zones"></a> [zones](#input\_zones) | A list of a one or more Availability Zones, where the Redis Cache should be allocated. | `list(number)` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_redis_capacity"></a> [redis\_capacity](#output\_redis\_capacity) | Redis capacity |
| <a name="output_redis_family"></a> [redis\_family](#output\_redis\_family) | Redis family |
| <a name="output_redis_hostname"></a> [redis\_hostname](#output\_redis\_hostname) | Redis instance hostname |
| <a name="output_redis_id"></a> [redis\_id](#output\_redis\_id) | Redis instance id |
| <a name="output_redis_name"></a> [redis\_name](#output\_redis\_name) | Redis instance name |
| <a name="output_redis_port"></a> [redis\_port](#output\_redis\_port) | Redis instance port |
| <a name="output_redis_primary_access_key"></a> [redis\_primary\_access\_key](#output\_redis\_primary\_access\_key) | Redis primary access key |
| <a name="output_redis_private_static_ip_address"></a> [redis\_private\_static\_ip\_address](#output\_redis\_private\_static\_ip\_address) | Redis private static IP address |
| <a name="output_redis_secondary_access_key"></a> [redis\_secondary\_access\_key](#output\_redis\_secondary\_access\_key) | Redis secondary access key |
| <a name="output_redis_sku_name"></a> [redis\_sku\_name](#output\_redis\_sku\_name) | Redis SKU name |
| <a name="output_redis_ssl_port"></a> [redis\_ssl\_port](#output\_redis\_ssl\_port) | Redis instance SSL port |
<!-- END_TF_DOCS -->