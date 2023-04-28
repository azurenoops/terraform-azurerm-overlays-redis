# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

###########################
# Global Configuration   ##
###########################

variable "environment" {
  description = "The Terraform backend environment e.g. public or usgovernment"
  type        = string
  default     = null
}

variable "location" {
  description = "The location/region to keep all your network resources. To get the list of all locations with table format from azure cli, run 'az account list-locations -o table'"
  type        = string
}

variable "org_name" {
  description = "A name for the organization. It defaults to anoa."
  type        = string
  default     = "anoa"
}

variable "workload_name" {
  description = "A name for the workload. It defaults to hub-core."
  type        = string
  default     = "hub-core"
}

variable "deploy_environment" {
  description = "The environment to deploy. It defaults to dev."
  type        = string
  default     = "dev"
}

variable "tags" {
  description = "A map of tags to add to all resources"
  default     = {}
  type        = map(string)
}

#######################
# RG Configuration   ##
#######################

variable "existing_resource_group_name" { # This is used for the redis resource group
  description = "Name of the existing resource group"
  default     = null
}

#####################################
# Private Endpoint Configuration   ##
#####################################
variable "enable_private_endpoint" {
  description = "Manages a Private Endpoint to Azure Container Registry. Default is false."
  default     = false
}

variable "existing_private_dns_zone" {
  description = "Name of the existing private DNS zone"
  default     = null
}

variable "private_subnet_address_prefix" {
  description = "The name of the subnet for private endpoints"
  default     = null
}

variable "virtual_network_name" {
  description = "Name of the virtual network for the private endpoint"
  default     = null
}

variable "existing_subnet_name" { # This is used for the private endpoint
  description = "The name of the existing subnet"
  default     = null
  
}
################################
# Redis Cache Configuration   ##
################################

variable "capacity" {
  description = "Redis size: (Basic/Standard: 1,2,3,4,5,6) (Premium: 1,2,3,4)  https://docs.microsoft.com/fr-fr/azure/redis-cache/cache-how-to-premium-clustering"
  type        = number
  default     = 2
}

variable "sku_name" {
  description = "Redis Cache Sku name. Can be Basic, Standard or Premium"
  type        = string
  default     = "Premium"
}

variable "cluster_shard_count" {
  description = "Number of cluster shards desired"
  type        = number
  default     = 3
}

variable "redis_configuration" {
  description = "Additional configuration for the Redis instance. Some of the keys are set automatically. See https://www.terraform.io/docs/providers/azurerm/r/redis_cache.html#redis_configuration for full reference."
  type = object({
    aof_backup_enabled              = optional(bool)
    aof_storage_connection_string_0 = optional(string)
    aof_storage_connection_string_1 = optional(string)
    enable_authentication           = optional(bool)
    maxmemory_reserved              = optional(number)
    maxmemory_delta                 = optional(number)
    maxmemory_policy                = optional(string)
    maxfragmentationmemory_reserved = optional(number)
    rdb_backup_enabled              = optional(bool)
    rdb_backup_frequency            = optional(number)
    rdb_backup_max_snapshot_count   = optional(number)
    rdb_storage_connection_string   = optional(string)
    notify_keyspace_events          = optional(string)
  })
  default = {}
}

variable "authorized_cidrs" {
  description = "Map of authorized cidrs"
  type        = map(string)
  default     = {}
}

variable "allow_non_ssl_connections" {
  description = "Activate non SSL port (6779) for Redis connection"
  type        = bool
  default     = false
}

variable "minimum_tls_version" {
  description = "The minimum TLS version"
  type        = string
  default     = "1.2"
}

variable "private_static_ip_address" {
  description = "The Static IP Address to assign to the Redis Cache when hosted inside the Virtual Network. Changing this forces a new resource to be created."
  type        = string
  default     = null
}

variable "allow_auto_registration" {
  description = "Allow auto registration of the network hosts to private DNS."
  type        = bool
  default     = false
}
variable "data_persistence_enabled" {
  description = "\"true\" to enable data persistence."
  type        = bool
  default     = true
}

variable "data_persistence_frequency_in_minutes" {
  description = "Data persistence snapshot frequency in minutes."
  type        = number
  default     = 60
}

variable "data_persistence_max_snapshot_count" {
  description = "Max number of data persistence snapshots."
  type        = number
  default     = null
}


variable "data_persistence_storage_account_tier" {
  description = "Replication type for the Storage Account used for data persistence."
  type        = string
  default     = "Premium"
}

variable "data_persistence_storage_account_replication" {
  description = "Replication type for the Storage Account used for data persistence."
  type        = string
  default     = "LRS"
}

variable "redis_version" {
  description = "Redis version to deploy. Allowed values are 4 or 6"
  type        = number
  default     = 6
}

variable "zones" {
  description = "A list of a one or more Availability Zones, where the Redis Cache should be allocated."
  default     = null
  type        = list(number)
}

variable "patch_schedules" {
  description = "A list of Patch Schedule, Azure Cache for Redis patch schedule is used to install important software updates in specified time window."
  default     = []
  nullable    = false
  type = list(object({
    day_of_week        = string
    start_hour_utc     = optional(string)
    maintenance_window = optional(string)
  }))
}