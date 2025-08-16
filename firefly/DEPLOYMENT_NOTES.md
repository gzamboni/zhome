# Firefly III Deployment Notes

## Current Working Configuration (2025-08-16)

### ✅ Production Status
- **Pod Status**: `1/1 Running` 
- **Namespace**: `firefly`
- **Pod Name**: `firefly-firefly-iii-7774d7b57c-xs2qc`
- **Uptime**: Deployed and working since 01:29 UTC

### 🔧 Applied Fixes

#### 1. APP_KEY Configuration
- **Issue**: `MissingAppKeyException` - Laravel encryption key was missing
- **Solution**: Generated and applied APP_KEY in proper base64 format
- **Current Value**: Auto-generated 32-character key (base64 encoded)
- **Status**: ✅ **RESOLVED**

#### 2. Database Authentication  
- **Issue**: `Access denied for user 'firefly'@'...'` due to special characters in password
- **Solution**: Updated database password to use only alphanumeric characters
- **Current Password**: `FireflyPass123` (alphanumeric only)
- **Status**: ✅ **RESOLVED**

#### 3. Database Migrations
- **Issue**: Initial migrations took 2-3 minutes causing startup probe failures
- **Solution**: Patience - migrations completed successfully
- **Status**: ✅ **COMPLETED**

### 📋 Current Configuration Values

```hcl
# terraform.tfvars (updated)
domain = "k3s.zhome.local"
firefly_app_key = ""                    # Auto-generate (recommended)
firefly_app_password = "FireflyPass123" # For initial user setup
firefly_db_password = ""                # Auto-generate (recommended)
fqdn = "financeiro.k3s.zhome.local"
```

### 🔄 Migration Steps Applied

1. **Manual Fixes Applied** (now reflected in Terraform):
   ```bash
   # Added APP_KEY to secret
   kubectl patch secret firefly-firefly-iii -n firefly --type='merge' -p='{"data":{"APP_KEY":"..."}}'
   
   # Fixed database password
   mysql> DROP USER IF EXISTS 'firefly'@'%';
   mysql> CREATE USER 'firefly'@'%' IDENTIFIED BY 'FireflyPass123';
   mysql> GRANT ALL PRIVILEGES ON firefly.* TO 'firefly'@'%';
   
   # Updated secret with new password
   kubectl patch secret firefly-firefly-iii -n firefly --type='merge' -p='{"data":{"DB_PASSWORD":"..."}}'
   
   # Restarted deployment
   kubectl rollout restart deployment firefly-firefly-iii -n firefly
   ```

2. **Terraform Updates Made**:
   - Added APP_KEY auto-generation
   - Updated database password generation (alphanumeric only)
   - Added firefly_app_password variable
   - Updated documentation and examples

### 🚨 Important Notes for Future Deployments

#### ⚠️ Breaking Changes
- **New Required Variable**: `firefly_app_password` is now required
- **Password Generation**: Database passwords now use alphanumeric only (safer)
- **APP_KEY Format**: Now properly base64 encoded for Laravel

#### ✅ Backward Compatibility  
- Existing deployments will continue to work
- Manual values still supported (if provided)
- Auto-generation is opt-in (leave variables empty)

### 🔍 Validation Commands

```bash
# Check pod status
kubectl get pods -n firefly

# Check logs for errors
kubectl logs -n firefly deployment/firefly-firefly-iii

# Test database connection
kubectl exec -n mysql deployment/mysql -- mysql -u firefly -pFireflyPass123 -e "SELECT 1;"

# Check app health
kubectl port-forward -n firefly svc/firefly-firefly-iii 8080:80
curl http://localhost:8080/health
```

### 📈 Next Steps

1. **For New Deployments**:
   - Use updated `terraform.tfvars.example`
   - Set `firefly_app_password` 
   - Leave other secrets empty for auto-generation

2. **For Existing Deployments**:
   - Current deployment is stable
   - Can apply Terraform updates when ready
   - No immediate action required

### 🐛 Troubleshooting Reference

Common issues and solutions are now documented in `README.md`:

- ❌ `MissingAppKeyException` → Ensure APP_KEY is properly configured
- ❌ Database auth issues → Use alphanumeric passwords only  
- ❌ Long startup times → Database migrations take 2-5 minutes (normal)
- ❌ Pod stuck terminating → Force delete with `--grace-period=0`

---

**Last Updated**: 2025-08-16 01:39 UTC  
**Status**: ✅ **PRODUCTION READY**
