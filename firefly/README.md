# Firefly III Terraform Deployment

This Terraform configuration deploys Firefly III on Kubernetes using the official Helm chart.

## Features

- 🔐 **Auto-generated secrets**: APP_KEY and database passwords are automatically generated if not provided
- 🗄️ **MySQL integration**: Automatically creates database and user in existing MySQL deployment
- 🔧 **Production ready**: Configurable resources, persistence enabled
- 🚀 **Helm-based**: Uses official Firefly III Helm chart v1.5.0
- 🔄 **Ingress support**: Traefik-based ingress for external access

## Quick Start

1. Copy the example configuration:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. Edit `terraform.tfvars` with your values:
   ```hcl
   domain = "yourdomain.com"
   firefly_app_password = "your-secure-password"
   fqdn = "finance.yourdomain.com"
   ```

3. Deploy:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

## Configuration

### Required Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `domain` | Base domain for infrastructure | `"example.com"` |
| `firefly_app_password` | Initial user password | `"SecurePassword123"` |

### Optional Variables (Auto-generated if empty)

| Variable | Description | Default/Auto-gen |
|----------|-------------|------------------|
| `firefly_app_key` | Laravel encryption key | Auto-generated (32 chars) |
| `firefly_db_password` | Database password | Auto-generated (alphanumeric) |

### Other Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `fqdn` | Fully qualified domain name | `"fin.local"` |
| `mysql_namespace` | MySQL namespace | `"mysql"` |
| `mysql_service_name` | MySQL service name | `"mysql"` |
| `firefly_db_name` | Database name | `"firefly"` |
| `firefly_db_user` | Database user | `"firefly"` |

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Traefik       │────│  Firefly III    │────│     MySQL       │
│   (Ingress)     │    │    (Helm)       │    │  (Database)     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
        │                       │                       │
        │              ┌─────────────────┐              │
        └──────────────│  Kubernetes     │──────────────┘
                       │    Cluster      │
                       └─────────────────┘
```

## Security Best Practices

### ✅ What This Configuration Does Right

- **Auto-generates secure passwords**: No hardcoded credentials
- **Uses alphanumeric passwords**: Avoids MySQL authentication issues with special characters
- **Proper base64 encoding**: APP_KEY follows Laravel's `base64:` format
- **Sensitive variables**: All secrets marked as sensitive in Terraform
- **Minimal permissions**: Database user only has access to Firefly database

### 🔒 Additional Security Recommendations

1. **Use external secret management**:
   - Consider using Kubernetes External Secrets or HashiCorp Vault
   - Store Terraform state securely (encrypted S3, etc.)

2. **Network policies**:
   - Implement Kubernetes NetworkPolicies to restrict traffic
   - Use private registries for container images

3. **Regular updates**:
   - Keep Firefly III image updated
   - Monitor security advisories

## Troubleshooting

### Common Issues

#### ❌ Pod failing with "MissingAppKeyException"
**Cause**: APP_KEY not properly set
**Solution**: This should be auto-resolved with the current configuration. If still occurring:
```bash
kubectl logs -n firefly deployment/firefly-firefly-iii
```

#### ❌ Database connection refused / Access denied
**Cause**: Database password contains special characters causing MySQL auth issues
**Solution**: Current config auto-generates alphanumeric passwords. If using custom password:
- Use only letters and numbers
- Avoid special characters like `!`, `@`, `#`, etc.

#### ❌ Pod stuck in "Terminating"
**Solution**: Force delete the pod
```bash
kubectl delete pod <pod-name> -n firefly --force --grace-period=0
```

#### ❌ Database migrations taking too long
**Cause**: Initial database setup can take 2-5 minutes
**Solution**: Be patient, check logs:
```bash
kubectl logs -n firefly deployment/firefly-firefly-iii -f
```

### Debugging Commands

```bash
# Check pod status
kubectl get pods -n firefly

# Check pod logs
kubectl logs -n firefly deployment/firefly-firefly-iii

# Check database connection
kubectl exec -n mysql deployment/mysql -- mysql -u firefly -p<password> -e "SELECT 1;"

# Port forward to test locally
kubectl port-forward -n firefly svc/firefly-firefly-iii 8080:80

# Check secrets
kubectl get secret -n firefly firefly-firefly-iii -o yaml
```

## Changelog

### Version 2.0 (Current)
- ✅ **Added APP_KEY auto-generation**: Fixes Laravel encryption requirements
- ✅ **Fixed database authentication**: Uses alphanumeric passwords only
- ✅ **Improved error handling**: Better password generation logic
- ✅ **Enhanced documentation**: Comprehensive troubleshooting guide

### Version 1.0 (Legacy)
- ❌ Missing APP_KEY configuration
- ❌ Database passwords with problematic special characters
- ❌ Manual secret management required

## Requirements

- Terraform >= 1.0
- Kubernetes cluster with:
  - Helm support
  - Traefik ingress controller
  - MySQL deployment in `mysql` namespace
- kubectl configured for your cluster

## Dependencies

This module depends on:
- Existing MySQL deployment
- Traefik ingress controller
- Kubernetes cluster with persistent volume support

## Contributing

When making changes:
1. Test with a fresh deployment
2. Update this README
3. Update `terraform.tfvars.example`
4. Test rollback scenarios

## Support

For issues:
1. Check the troubleshooting section above
2. Review pod logs: `kubectl logs -n firefly deployment/firefly-firefly-iii`
3. Verify MySQL connectivity from the pod
4. Check Firefly III documentation: https://docs.firefly-iii.org/
