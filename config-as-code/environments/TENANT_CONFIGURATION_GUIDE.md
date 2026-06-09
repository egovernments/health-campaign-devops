# Tenant Configuration Guide

## Overview
This guide provides instructions for creating and configuring new tenants in the HCM (Health Campaign Management) platform.

## Creating a New Tenant Configuration

### Step 1: Copy Base Configuration
```bash
cp environments/<base-tenant>-afro-hcm.yaml environments/<new-tenant>-afro-hcm.yaml
```

### Step 2: Update Tenant-Specific Values

#### Required Changes:
1. **Namespace**: Replace all occurrences of the base tenant namespace with the new tenant namespace
   - `namespace: <old-tenant>` → `namespace: <new-tenant>`

2. **Kafka Topics**: Update all Kafka topic names to use the new tenant prefix
   - Pattern: `<old-tenant>-*` → `<new-tenant>-*`
   - Examples:
     - `save-attendance-log-topic`
     - `update-attendance-log-topic`
     - `transformer-producer-*-topic`
     - `save-project-*-topic`
     - `update-project-*-topic`

3. **Service References**: Update all service name references
   - `<old-tenant>-census-service` → `<new-tenant>-census-service`
   - `<old-tenant>-plan-service` → `<new-tenant>-plan-service`
   - `<old-tenant>-project-factory` → `<new-tenant>-project-factory`
   - `<old-tenant>-resource-generator` → `<new-tenant>-resource-generator`

4. **Ingress Contexts**: Update ingress paths
   - `context: "<old-tenant>/*"` → `context: "<new-tenant>/*"`

5. **Database Configuration**:
   - `DB_SCHEMA: <old-tenant>` → `DB_SCHEMA: <new-tenant>`
   - `defaultTenantId: <old-tenant>` → `defaultTenantId: <new-tenant>`
   - `tenantId: "<old-tenant>"` → `tenantId: "<new-tenant>"`
   - `state-level-tenantid: "<old-tenant>"` → `state-level-tenantid: "<new-tenant>"`

6. **Locale Configuration**:
   - `defaultLocale: 'en_<OLD-TENANT>'` → `defaultLocale: 'en_<NEW-TENANT>'`

7. **Group IDs**: Update Kafka consumer group IDs
   - `group-id: "<old-tenant>-*"` → `group-id: "<new-tenant>-*"`

## External Dependencies

### 1. AWS S3 Global Configuration Files
Create tenant-specific JavaScript configuration files:
- `globalConfigs.js` - Main HCM UI configuration
- `globalConfigsWorkbench.js` - Workbench UI configuration
- `globalConfigsPayments.js` - Payments UI configuration
- `globalConfigsDashboard.js` - Dashboard UI configuration
- `globalConfigsConsole.js` - Console UI configuration
- `globalConfigsCoreUI.js` - Core UI configuration

Upload to appropriate S3 buckets and update URLs in the configuration.

### 2. Kubernetes Resources

#### Create Namespace:
```bash
kubectl create namespace <new-tenant>
```

#### Create Required Secrets:
```bash
kubectl create secret generic db-secret -n <new-tenant> \
  --from-literal=username=<db-user> \
  --from-literal=password=<db-password>
```

### 3. Database Setup

#### Create Database Schema:
```sql
CREATE SCHEMA IF NOT EXISTS <new-tenant>;
GRANT ALL PRIVILEGES ON SCHEMA <new-tenant> TO <app-user>;
```

### 4. Git Repository Configuration
For dashboard analytics, ensure the configuration repository has:
```
health-campaign-config/
└── egov-dss-dashboards/
    └── <new-tenant>/
        └── dashboard-analytics/
            └── *.json
```

### 5. ArgoCD Configuration

#### Create ArgoCD Resources:
Create the following files in `config-as-code/helm/charts/argo-cd/<new-tenant>/`:

1. **AppProject** (`<new-tenant>-app-project.yaml`):
```yaml
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: <new-tenant>-project
  namespace: argocd
spec:
  sourceRepos:
    - git@github.com:HCM-WHO-AFRO/health-campaign-devops.git
  destinations:
    - namespace: '*'
      server: https://kubernetes.default.svc
```

2. **Frontend ApplicationSet** (`<new-tenant>-app-set-frontend.yaml`):
```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: who-afro-<new-tenant>-appset-frontend
  namespace: argocd
spec:
  generators:
    - list:
        elements:
          - name: workbench-ui
          - name: hcm-digit-ui
          - name: dashboard-ui
          - name: payments-ui
          - name: dss-dashboard
          - name: core-ui
          - name: console
          - name: microplan-ui
  template:
    metadata:
      name: '<new-tenant>-{{name}}'
    spec:
      project: <new-tenant>-project
      source:
        repoURL: git@github.com:HCM-WHO-AFRO/health-campaign-devops.git
        targetRevision: <your-branch>
        path: config-as-code/helm/charts/frontend/{{name}}
        helm:
          valueFiles:
            - values.yaml
            - ../../../../environments/<new-tenant>-afro-hcm.yaml
      destination:
        server: https://kubernetes.default.svc
        namespace: <new-tenant>
      syncPolicy:
        automated:
          prune: false
          selfHeal: true
        syncOptions:
          - ApplyOutOfSyncOnly=true
          - ServerSideApply=true
```

3. **Business ApplicationSet** (`<new-tenant>-app-set-business.yaml`):
```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: who-afro-<new-tenant>-appset-business
  namespace: argocd
spec:
  generators:
    - list:
        elements:
          - name: dashboard-analytics
  # Similar template structure as frontend
```

4. **Health Services ApplicationSet** (`<new-tenant>-app-set-health.yaml`):
```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: who-afro-<new-tenant>-appset-health
  namespace: argocd
spec:
  generators:
    - list:
        elements:
          - name: project-factory
          - name: transformer
          - name: resource-generator
          - name: plan-service
          - name: excel-ingestion
          - name: census-service
          - name: auth-proxy
          - name: health-expense-calculator
  # Similar template structure
```

## Service Configuration Matrix

| Service | Namespace Isolated | Shared Across Tenants | Notes |
|---------|-------------------|----------------------|--------|
| transformer | Yes | No | Requires tenant-specific topics |
| hcm-digit-ui | Yes | No | Tenant-specific UI |
| census-service | Yes | No | Tenant data isolation |
| plan-service | Yes | No | Tenant-specific planning |
| project-factory | Yes | No | Tenant project management |
| workbench-ui | No | Yes | Shared UI, context-based |
| payments-ui | No | Yes | Shared payment interface |
| dashboard-ui | No | Yes | Shared analytics UI |
| excel-ingestion | Yes | No | Tenant data processing |

## Configuration Checklist

### Pre-Deployment:
- [ ] Configuration file created from template
- [ ] All tenant references updated
- [ ] Kafka topic names updated
- [ ] Service names updated
- [ ] Database schema created
- [ ] Kubernetes namespace created
- [ ] S3 configuration files uploaded
- [ ] Ingress paths configured
- [ ] Secrets created in namespace

### Deployment:

#### Step 1: Commit and Push Configuration
```bash
# Add new tenant configuration files
git add environments/<new-tenant>-afro-hcm.yaml
git add helm/charts/argo-cd/<new-tenant>/

# Commit changes
git commit -m "Add <new-tenant> tenant configuration"

# Push to repository
git push origin <your-branch>
```

#### Step 2: Apply ArgoCD Configuration
```bash
# Create namespace
kubectl create namespace <new-tenant>

# Apply ArgoCD project
kubectl apply -f config-as-code/helm/charts/argo-cd/<new-tenant>/<new-tenant>-app-project.yaml

# Apply ApplicationSets
kubectl apply -f config-as-code/helm/charts/argo-cd/<new-tenant>/<new-tenant>-app-set-frontend.yaml
kubectl apply -f config-as-code/helm/charts/argo-cd/<new-tenant>/<new-tenant>-app-set-business.yaml
kubectl apply -f config-as-code/helm/charts/argo-cd/<new-tenant>/<new-tenant>-app-set-health.yaml

# Verify applications are created
kubectl get applications -n argocd | grep <new-tenant>
```

#### Step 3: Sync Applications
```bash
# Sync all applications (or use ArgoCD UI)
argocd app sync -l app.kubernetes.io/instance=<new-tenant>

# Or sync individual applications
argocd app sync <new-tenant>-<service-name>
```

#### Verification Checklist:
- [ ] All ArgoCD applications show "Healthy" status
- [ ] Verify all pods are running: `kubectl get pods -n <new-tenant>`
- [ ] Check ingress endpoints: `kubectl get ingress -n <new-tenant>`
- [ ] Test inter-service communication
- [ ] Verify Kafka topic creation
- [ ] Test database connectivity

### Post-Deployment:
- [ ] Verify UI accessibility
- [ ] Test authentication flow
- [ ] Check logging and monitoring
- [ ] Validate data isolation
- [ ] Test end-to-end workflows

## Common Configuration Patterns

### Kafka Topics Naming Convention:
```
<tenant>-<action>-<entity>-<suffix>
```
Examples:
- `<tenant>-save-project-task-topic`
- `<tenant>-update-household-topic`
- `<tenant>-transformer-producer-bulk-stock-index-v1-topic`

### Service Naming Convention:
```
<tenant>-<service-name>
```
Examples:
- `<tenant>-census-service`
- `<tenant>-plan-service`
- `<tenant>-project-factory`

### Ingress Path Convention:
```
/<tenant>/<service-endpoint>
```
Examples:
- `/<tenant>/hcm-digit-ui`
- `/<tenant>/transformer`
- `/<tenant>/census-service`

## Environment-Specific Configurations

### Development Environment:
- Lower replica counts (1-2)
- Reduced resource limits
- Debug logging enabled
- HPA disabled

### UAT Environment:
- Moderate replica counts (2-3)
- Standard resource limits
- Info logging level
- HPA enabled with conservative scaling

### Production Environment:
- Higher replica counts (3+)
- Increased resource limits
- Warning/Error logging only
- HPA enabled with appropriate thresholds

## Troubleshooting

### Common Issues:

1. **Service Discovery Failures**:
   - Verify service names match in configuration
   - Check namespace isolation
   - Validate DNS resolution

2. **Kafka Connection Issues**:
   - Ensure topic names are correctly prefixed
   - Verify consumer group IDs
   - Check Kafka broker connectivity

3. **Database Connection Failures**:
   - Verify schema exists and permissions granted
   - Check connection string uses correct schema
   - Validate network connectivity

4. **Ingress Not Working**:
   - Verify ingress controller is running
   - Check ingress paths and annotations
   - Validate SSL/TLS certificates

5. **ArgoCD Sync Failures**:
   - Ensure configuration file exists in git repository
   - Verify branch name in ApplicationSet configuration
   - Check ArgoCD has repository access permissions
   - Review application logs: `argocd app logs <new-tenant>-<service>`
   - Common error: "failed to execute helm template" - usually means values file not found in repo

## Security Considerations

1. **Data Isolation**:
   - Each tenant uses separate Kafka topics
   - Database schemas are isolated per tenant
   - Kubernetes namespaces provide resource isolation

2. **Access Control**:
   - RBAC policies per namespace
   - Service accounts with minimal permissions
   - Network policies for inter-service communication

3. **Secrets Management**:
   - Use Kubernetes secrets for sensitive data
   - Rotate credentials regularly
   - Encrypt secrets at rest

## Monitoring and Logging

### Key Metrics to Monitor:
- Pod resource utilization
- Kafka lag per consumer group
- Database connection pool usage
- API response times
- Error rates per service

### Logging Strategy:
- Centralized logging per tenant
- Structured logging format
- Log retention policies
- Alert rules for critical errors

## Maintenance

### Regular Tasks:
- Review and update resource limits
- Clean up old Kafka topics
- Database maintenance and optimization
- Security patches and updates
- Configuration drift detection

### Scaling Considerations:
- Monitor resource usage trends
- Plan capacity for growth
- Implement auto-scaling where appropriate
- Regular load testing