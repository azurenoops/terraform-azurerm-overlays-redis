# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

# Generic naming variables
variable "name_prefix" {
  description = "Optional prefix for the generated name"
  type        = string
  default     = ""
}

variable "name_suffix" {
  description = "Optional suffix for the generated name"
  type        = string
  default     = ""
}

variable "use_naming" {
  description = "Use the Azure CAF naming provider to generate default resource name. `custom_name` override this if set. Legacy default name is used if this is set to `false`."
  type        = bool
  default     = true
}

# Custom naming override
variable "custom_name" {
  description = "Custom name of Redis Server"
  type        = string
  default     = ""
}

variable "custom_resource_group_name" {
  description = "The name of the resource group in which the resources will be created. If not provided, a new resource group will be created with the name 'rg-<org_name>-<environment>-<workload_name>'"
  type        = string
  default     = null
}

variable "data_persistence_storage_custom_name" {
  description = "Custom name for the Storage Account used for Redis data persistence."
  type        = string
  default     = ""
}