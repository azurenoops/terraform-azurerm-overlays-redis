output "test_redis_id" {
  value = module.mod_redis.redis_id
}

output "test_redis_name" {
  value       = module.mod_redis.redis_name
  description = "Redis instance name"
}

output "test_redis_hostname" {
  value       = module.mod_redis.redis_hostname
  description = "Redis instance hostname"
}
