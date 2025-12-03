# resource "adguard_rewrite" "adhome_rewrite_entry" {
#   depends_on = [kubernetes_deployment.adguard]

#   for_each = { for entry in var.rewrites : entry.hostname => entry if entry.enabled }
#   domain   = each.value.hostname
#   answer   = each.value.ip
# }
