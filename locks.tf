# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

#------------------------------------------------------------
# Storage Account Lock configuration - Default (required). 
#------------------------------------------------------------
resource "azurerm_management_lock" "storage_account_level_lock" {
  count      = var.enable_resource_locks ? 1 : 0
  name       = "${local.storage_name}-${var.lock_level}-lock"
  scope      = azurerm_storage_account.redis_storage.0.id
  lock_level = var.lock_level
  notes      = "Redis Storage Account '${local.storage_name}' is locked with '${var.lock_level}' level."
}

resource "azurerm_management_lock" "redis_level_lock" {
  count      = var.enable_resource_locks ? 1 : 0
  name       = "${local.redis_name}-${var.lock_level}-lock"
  scope      = azurerm_redis_cache.redis.id
  lock_level = var.lock_level
  notes      = "Redis Cache '${local.redis_name}' is locked with '${var.lock_level}' level."
}