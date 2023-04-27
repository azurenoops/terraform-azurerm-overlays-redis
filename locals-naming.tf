locals {
  # Naming locals/constants
  name_prefix = lower(var.name_prefix)
  name_suffix = lower(var.name_suffix)

  resource_group_name = var.existing_resource_group_name
  location            = data.azurerm_resource_group.rgrp.*.location
  redis_name          = coalesce(var.custom_name, data.azurenoopsutils_resource_name.redis.result)
  storage_name        = coalesce(var.data_persistence_storage_custom_name, data.azurenoopsutils_resource_name.data_storage.result)
}
