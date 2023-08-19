<!-- BEGIN_TF_DOCS -->
# ZHOME Terraform automation

This repository contains the new terraform modules to configure my personal K8s cluster and all its applications installed.

<!-- markdownlint-disable MD001 -->
### TL;DR

1. [install asdf](https://asdf-vm.com/guide/getting-started.html)
    1. Install the following *asdf* plugins:
        - Python 3.11.3
        - golang 1.19.5
        - terraform 1.4.6
2. [install pre-commit](https://pre-commit.com/#install)
    - Prerequisites:
        - [Python](https://docs.python.org/3/using/index.html)
        - [Pip](https://pip.pypa.io/en/stable/installation/)
3. configure pre-commit: `pre-commit install`
4. install required tools
    - [tflint](https://github.com/terraform-linters/tflint)
    - [tfsec](https://aquasecurity.github.io/tfsec/v1.0.11/)
    - [terraform-docs](https://github.com/terraform-docs/terraform-docs)

## Module Documentation

**Do not manually update README.md**. README.md is automatically generated by pulling in content from other files.

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >=0.13 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | 2.9.0 |
| <a name="requirement_kubectl"></a> [kubectl](#requirement\_kubectl) | 1.14.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | 2.20.0 |
| <a name="requirement_postgresql"></a> [postgresql](#requirement\_postgresql) | 1.20.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_dyndns"></a> [dyndns](#module\_dyndns) | ./dyndns | n/a |
| <a name="module_helms"></a> [helms](#module\_helms) | ./helm | n/a |
| <a name="module_qdrant"></a> [qdrant](#module\_qdrant) | ./qdrant_db | n/a |
| <a name="module_zcluster"></a> [zcluster](#module\_zcluster) | ./zcluster | n/a |
| <a name="module_zvault"></a> [zvault](#module\_zvault) | ./vaultwarden | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cifs_backup_target"></a> [cifs\_backup\_target](#input\_cifs\_backup\_target) | value of the cifs backup server | `any` | n/a | yes |
| <a name="input_default_smtp_config"></a> [default\_smtp\_config](#input\_default\_smtp\_config) | Object containing default SMTP configuration | <pre>object({<br>    server = object({<br>      host      = string<br>      port      = string<br>      security  = string<br>      timeout   = string<br>      helo_name = string<br>    })<br>    auth = object({<br>      username = string<br>      password = string<br>    })<br>    email_config = object({<br>      from         = string<br>      from_name    = string<br>      embed_images = bool<br>    })<br>  })</pre> | n/a | yes |
| <a name="input_google_dynamic_dns_fqdn"></a> [google\_dynamic\_dns\_fqdn](#input\_google\_dynamic\_dns\_fqdn) | The FQDN of the dynamic DNS record to update | `string` | n/a | yes |
| <a name="input_google_dynamic_dns_password"></a> [google\_dynamic\_dns\_password](#input\_google\_dynamic\_dns\_password) | The password to use for dynamic DNS updates | `string` | n/a | yes |
| <a name="input_google_dynamic_dns_username"></a> [google\_dynamic\_dns\_username](#input\_google\_dynamic\_dns\_username) | The username to use for dynamic DNS updates | `string` | n/a | yes |
| <a name="input_k3s_config"></a> [k3s\_config](#input\_k3s\_config) | Object containing k3s configuration | <pre>object({<br>    cluster_name = string<br>    local_domain = string<br>    context      = string<br>    nodes = map(object({<br>      ip   = string<br>      type = string<br>    }))<br>    users = map(object({<br>      username = string<br>      password = string<br>    }))<br>  })</pre> | n/a | yes |
| <a name="input_metallb_address_pool"></a> [metallb\_address\_pool](#input\_metallb\_address\_pool) | Defines the MetalLB address pool, a map of name and addresses (ip ranges or ip/mask) | <pre>object({<br>    name      = string<br>    addresses = list(string)<br>  })</pre> | n/a | yes |
| <a name="input_vaultwarden_config"></a> [vaultwarden\_config](#input\_vaultwarden\_config) | Object containing vaultwarden configuration | <pre>object({<br>    timezone             = string<br>    default_vault_domain = string<br>    ingress_hosts        = list(string)<br>    allow_signups        = bool<br>    domain_white_list    = list(string)<br>    org_creation_users   = list(string)<br>  })</pre> | n/a | yes |
| <a name="input_cifs_backup_password"></a> [cifs\_backup\_password](#input\_cifs\_backup\_password) | value of the cifs backup password | `string` | `"backup"` | no |
| <a name="input_cifs_backup_user"></a> [cifs\_backup\_user](#input\_cifs\_backup\_user) | value of the cifs backup user | `string` | `"backup"` | no |
| <a name="input_flowise_config"></a> [flowise\_config](#input\_flowise\_config) | Object containing flowise configuration | <pre>object({<br>    enabled = bool<br>    auth = object({<br>      username   = string<br>      password   = string<br>      passphrase = string<br>    })<br>    ingress = object({<br>      enabled = bool<br>      hosts = object({<br>        internal_hostname = string<br>        external_hostname = string<br>      })<br>    })<br>    database = object({<br>      enabled  = bool<br>      port     = number<br>      username = string<br>      password = string<br>      database = string<br>    })<br>  })</pre> | <pre>{<br>  "auth": {<br>    "passphrase": "",<br>    "password": "",<br>    "username": "admin"<br>  },<br>  "database": {<br>    "database": "flowise",<br>    "enabled": false,<br>    "password": "",<br>    "port": 5432,<br>    "username": ""<br>  },<br>  "enabled": false,<br>  "ingress": {<br>    "enabled": true,<br>    "hosts": {<br>      "external_hostname": "",<br>      "internal_hostname": ""<br>    }<br>  }<br>}</pre> | no |
| <a name="input_kubeconfig"></a> [kubeconfig](#input\_kubeconfig) | Path to kubeconfig file | `string` | `"~/.kube/config"` | no |
| <a name="input_postgresql_config"></a> [postgresql\_config](#input\_postgresql\_config) | values to pass to the postgresql chart | <pre>object({<br>    enabled = bool<br>    auth = object({<br>      postgresPassword = string<br>    })<br>  })</pre> | <pre>{<br>  "auth": {<br>    "postgresPassword": ""<br>  },<br>  "enabled": false<br>}</pre> | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->