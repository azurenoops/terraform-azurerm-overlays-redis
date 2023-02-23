locals {
  default_tags = var.default_tags_enabled ? {
    env      = var.deploy_environment
    workload = var.workload_name
  } : {}
}
