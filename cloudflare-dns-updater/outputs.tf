output "namespace" {
  description = "The namespace where the DNS updater jobs are deployed"
  value       = kubernetes_namespace.cloudflare_dns_updater.metadata[0].name
}

output "link1_cronjob_name" {
  description = "The name of the CronJob for Link 1"
  value       = kubernetes_cron_job_v1.link1_dns_updater.metadata[0].name
}

output "link2_cronjob_name" {
  description = "The name of the CronJob for Link 2"
  value       = kubernetes_cron_job_v1.link2_dns_updater.metadata[0].name
}
