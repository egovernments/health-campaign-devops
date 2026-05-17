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
- [ ] Deploy using Helm/Kubernetes manifests
- [ ] Verify all pods are running
- [ ] Check ingress endpoints
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