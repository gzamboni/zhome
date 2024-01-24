locals {
  filter_list = var.filters
}

resource "adguard_list_filter" "adguard_list_filter_entry" {
  for_each = {
    for filter in local.filter_list :
    filter.name => filter
  }
  url     = each.value.url
  name    = each.value.name
  enabled = each.value.enabled
}

resource "adguard_user_rules" "adguard_user_rules_entry" {
  rules = var.user_rules
}
