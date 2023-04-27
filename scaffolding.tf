# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

#---------------------------------------------------------
# Azure Region Lookup
#----------------------------------------------------------
module "mod_azure_region_lookup" {
  source  = "azurenoops/overlays-azregions-lookup/azurerm"
  version = "~> 1.0.0"

  azure_region = var.location
}

#---------------------------------------------------------
# Resource Group Creation
#----------------------------------------------------------
data "azurerm_resource_group" "rgrp" {
  name  = var.existing_resource_group_name
}

