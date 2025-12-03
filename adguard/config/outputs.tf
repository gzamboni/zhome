output "config_applied" {
  description = "Indicates that the AdGuard configuration has been successfully applied"
  value       = "true"
  depends_on = [
    adguard_config.adguard_zhome,
    adguard_list_filter.adguard_list_filter_entry,
    adguard_user_rules.adguard_user_rules_entry,
    adguard_rewrite.adhome_rewrite_entry
  ]
}

output "filters_count" {
  description = "Number of filters applied"
  value       = length(adguard_list_filter.adguard_list_filter_entry)
}

output "rewrites_count" {
  description = "Number of DNS rewrites applied"
  value       = length(adguard_rewrite.adhome_rewrite_entry)
}

output "user_rules_count" {
  description = "Number of user rules applied"
  value       = length(var.user_rules)
}
