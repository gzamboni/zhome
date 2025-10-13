# Cloudflare DNS Updater Module

This Terraform module creates Kubernetes CronJobs that automatically update Cloudflare DNS records with the current external IP addresses of two different internet links. The module uses node selectors to ensure each job runs on a specific node (zcm01 or zcm02) to utilize the correct network path.

## Features

- Automatically updates Cloudflare DNS records with current external IP addresses
- Runs jobs on specific Kubernetes nodes to ensure correct network path usage
- Uses hostNetwork to ensure proper routing through the desired internet link
- Configurable update frequency (default: every 5 minutes)
- Secure storage of Cloudflare credentials using Kubernetes Secrets

## Requirements

- Kubernetes cluster with at least two nodes (zcm01 and zcm02)
- Cloudflare account with API access
- Terraform >= 0.13
- Kubernetes provider >= 2.0

## Usage

```terraform
module "cloudflare_dns_updater" {
  source              = "./cloudflare-dns-updater"
  cloudflare_email    = var.cloudflare_email
  cloudflare_api_key  = var.cloudflare_api_key
  cloudflare_zone_id  = var.cloudflare_zone_id
  link1_config        = {
    record_name = "_01"
    node_name   = "zcm01"
  }
  link2_config        = {
    record_name = "_v1v0"
    node_name   = "zcm02"
  }
  depends_on          = [module.zcluster]
}
```

## Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| namespace | Kubernetes namespace for DNS updater jobs | `string` | `"cloudflare-dns-updater"` | no |
| cloudflare_email | Cloudflare account email | `string` | n/a | yes |
| cloudflare_api_key | Cloudflare Global API Key | `string` | n/a | yes |
| cloudflare_zone_id | Cloudflare Zone ID for zamboni.dev | `string` | n/a | yes |
| schedule | Cron schedule for the DNS update jobs | `string` | `"*/5 * * * *"` | no |
| link1_config | Configuration for the first internet link | `object` | `{ record_name = "_01", node_name = "zcm01" }` | no |
| link2_config | Configuration for the second internet link | `object` | `{ record_name = "_v1v0", node_name = "zcm02" }` | no |
| domain | Domain name for the DNS records | `string` | `"zamboni.dev"` | no |
| resources | Resource limits and requests for the jobs | `object` | See below | no |

Default resources:
```terraform
{
  limits = {
    cpu    = "100m"
    memory = "128Mi"
  }
  requests = {
    cpu    = "50m"
    memory = "64Mi"
  }
}
```

## Outputs

| Name | Description |
|------|-------------|
| namespace | The namespace where the DNS updater jobs are deployed |
| link1_cronjob_name | The name of the CronJob for Link 1 |
| link2_cronjob_name | The name of the CronJob for Link 2 |

## How It Works

1. The module creates two CronJobs, each running on a specific node in your Kubernetes cluster
2. Each job uses hostNetwork: true to ensure it uses the network stack of the node it's running on
3. The jobs detect the external IP address by making a request to ipify.org
4. If the detected IP differs from the current DNS record, the job updates the Cloudflare DNS record

## Troubleshooting

If the jobs are not updating the DNS records as expected, check the following:

1. Ensure the nodes specified in the configuration (zcm01 and zcm02) exist in your cluster
2. Verify that the Cloudflare credentials are correct
3. Check the job logs for any error messages
4. Verify that the nodes have internet connectivity through their respective links
5. Ensure the Cloudflare Zone ID is correct for your domain
