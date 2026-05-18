# Network Migration Plan - AFROHCM Test Environment

## Changes Implemented

### 1. VNet Configuration
- **Name**: Changed from `AFROHCM-T-EUW-RG01-virtual-network` to `vnet-afrohcm-t-01`
- **Address Space**: Changed from `10.0.0.0/16` to `10.20.27.0/24`

### 2. Subnet Allocation
| Subnet | Name | CIDR | IPs | Purpose |
|--------|------|------|-----|---------|
| AKS | snet-aks-afrohcm-t-01 | 10.20.27.0/25 | 128 | Kubernetes nodes |
| PostgreSQL | snet-postgres-afrohcm-t-01 | 10.20.27.128/26 | 64 | Database with delegation |
| Reserved | (future) | 10.20.27.192/26 | 64 | Internal Load Balancer |

### 3. AKS Network Configuration
- **Network Plugin Mode**: `overlay` (Azure CNI Overlay)
- **Service CIDR**: Changed from `10.2.0.0/16` to `172.17.0.0/16`
- **DNS Service IP**: Changed from `10.2.0.10` to `172.17.0.10`
- **Pod CIDR**: `192.168.0.0/16` (internal overlay network)

## Migration Steps

### Step 1: Destroy Current Infrastructure
```bash
export TF_VAR_db_password="afrohcm@2024"
terraform destroy -auto-approve
```

### Step 2: Apply New Configuration
```bash
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

### Step 3: Get New Credentials
```bash
az aks get-credentials --resource-group AFROHCM-T-EUW-RG01 --name afrohcm-t-euw --overwrite-existing
```

### Step 4: Reinstall NGINX Ingress
```bash
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx --create-namespace \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"=/healthz
```

### Step 5: Restore Applications
```bash
# Apply backed up ingress configurations
kubectl apply -f ~/aks-backup/ingress-backup.yaml

# Restore ConfigMaps and Secrets
kubectl apply -f ~/aks-backup/egov-configs-backup.yaml

# Redeploy applications via Helm
helm upgrade --install <your-app-chart>
```

## Benefits
✅ No IP conflicts with AFRO network (10.2.0.0/16)
✅ Routable from AFRO hub networks for monitoring/administration
✅ Azure CNI Overlay prevents VNet IP exhaustion
✅ Follows Azure and WHO naming conventions
✅ Future-proof with reserved subnet space

## Important Notes
- All pod IPs will be from 192.168.0.0/16 (overlay network)
- Services will use 172.17.0.0/16 internally
- External connectivity unchanged (via Load Balancer/Ingress)
- Database connection remains the same (private endpoint)