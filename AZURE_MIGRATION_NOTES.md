# Azure GitHub Actions Migration Notes

## Successfully Migrated AWS to Azure Deployment

### Key Configuration Files:
- **Workflow**: `.github/workflows/create_cluster_azure.yaml`
- **Input Config**: `infra-as-code/terraform/sample-azure/input.yaml`
- **Terraform**: `infra-as-code/terraform/sample-azure/main.tf`
- **Init Script**: `infra-as-code/terraform/scripts/init-azure.go`

### Azure Credentials Required (GitHub Secrets):
- `ARM_CLIENT_ID`: Service Principal App ID
- `ARM_CLIENT_SECRET`: Service Principal Password  
- `ARM_TENANT_ID`: Azure AD Tenant ID
- `ARM_SUBSCRIPTION_ID`: Azure Subscription ID

### Critical Fixes Implemented:

1. **OIDC Issuer Configuration**
   - Added `oidc_issuer_enabled = true` in AKS module
   - Once enabled, cannot be disabled (prevents OIDCIssuerFeatureCannotBeDisabled error)

2. **Network Permissions for LoadBalancer**
   - Added Network Contributor role assignments for AKS managed identity
   - Required on both subnet and VNet for LoadBalancer creation
   - Fixes LinkedAuthorizationFailed error

3. **VM Size Compatibility**
   - Changed from `Standard_E4as_v5` to `Standard_D4_v4` for centralus region

4. **Backend Storage**
   - Azure CLI creates resource group, storage account, and container before Terraform
   - Prevents "ResourceNotFound" errors for backend

### LoadBalancer Details:
- **Service**: nginx-ingress-controller in egov namespace
- **Assigned IP**: 20.80.127.30
- **Domain**: Map to gha-demo.digit.org

### Service Principal Requirements:
- **Contributor** role on subscription/resource group
- **User Access Administrator** role (for automatic role assignments via Terraform)

### Important Commands:
```bash
# Get AKS credentials
az aks get-credentials --resource-group gha-demo-rg --name gha-demo-aks

# Check LoadBalancer status
kubectl get svc nginx-ingress-controller -n egov

# Manual role assignment (if needed)
az role assignment create \
  --assignee-object-id "<AKS_PRINCIPAL_ID>" \
  --assignee-principal-type ServicePrincipal \
  --scope "<SUBNET_ID>" \
  --role "Network Contributor"
```

### Branch: release-githubactions-azure
