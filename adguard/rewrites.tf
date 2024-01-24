resource "adguard_rewrite" "adhome_rewrite_entry" {
  for_each = { for entry in var.rewrites : entry.hostname => entry if entry.enabled }
  domain   = each.value.hostname
  answer   = each.value.ip
}
