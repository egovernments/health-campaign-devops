# ArgoCD Migration Plan - Monitoring Stack

## Overview
Migrate the monitoring stack from Helmfile to ArgoCD for GitOps-based deployment and management.

## Current State
- **Deployment Method**: Helmfile
- **Components**:
  1. Loki Stack (with TSDB configuration)
  2. Prometheus Stack (kube-prometheus-stack)
  3. Grafana
  4. Blackbox Exporter
  5. Jaeger (disabled)
  6. Kafka-UI (disabled)

## Migration Strategy

### Phase 1: Preparation
1. **Create ArgoCD directory structure**
   ```
   argocd-apps/
   ├── monitoring/
   │   ├── base/
   │   │   ├── loki-stack/
   │   │   ├── prometheus-stack/
   │   │   ├── grafana/
   │   │   └── blackbox-exporter/
   │   └── overlays/
   │       └── who-afro-hcm/
   │           ├── kustomization.yaml
   │           └── values/
   ```

2. **Set up ArgoCD Application manifests**
   - Create individual Application CRDs for each component
   - Use App of Apps pattern for managing multiple applications

### Phase 2: Service-by-Service Migration

#### Migration Order (Dependencies considered):
1. **Loki Stack** (Independent)
   - Priority: High (Already configured with TSDB)
   - Dependencies: Azure Storage Container

2. **Prometheus Stack** (Core monitoring)
   - Priority: High
   - Dependencies: None

3. **Blackbox Exporter** (Prometheus scrape target)
   - Priority: Medium
   - Dependencies: Prometheus Stack

4. **Grafana** (Visualization)
   - Priority: Medium
   - Dependencies: Loki, Prometheus

### Phase 3: Implementation Steps

#### For Each Service:

##### Step 1: Create ArgoCD Application
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: <service-name>
  namespace: argocd
spec:
  project: default
  source:
    repoURL: <git-repo-url>
    path: argocd-apps/monitoring/<service-path>
    targetRevision: HEAD
    helm:
      valueFiles:
        - values.yaml
  destination:
    server: https://kubernetes.default.svc
    namespace: monitoring
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

##### Step 2: Migrate Configuration
1. Copy existing values files from `values/` directory
2. Adapt for ArgoCD structure
3. Ensure all templating is compatible

##### Step 3: Validation
1. Deploy to staging/test environment
2. Verify functionality
3. Compare with Helmfile deployment

##### Step 4: Cutover
1. Deploy ArgoCD application
2. Monitor for issues
3. Remove from Helmfile
4. Update documentation

## Service-Specific Configurations

### 1. Loki Stack
**Special Considerations**:
- TSDB configuration in `loki-tsdb-values.yaml`
- Azure Storage credentials
- Persistent volume claims

**Files to Migrate**:
- `values/loki-stack.yaml`
- `values/loki-tsdb-values.yaml`

### 2. Prometheus Stack
**Special Considerations**:
- ServiceMonitor configurations
- AlertManager rules
- Persistent storage
- Scrape configurations

**Files to Migrate**:
- `values/prometheus.yaml`

### 3. Grafana
**Special Considerations**:
- Dashboard provisioning
- Datasource configuration
- Ingress settings

**Files to Migrate**:
- `values/grafana.yaml`

### 4. Blackbox Exporter
**Special Considerations**:
- Probe configurations
- ServiceMonitor for Prometheus

**Files to Migrate**:
- `values/blackbox-exporter.yaml`

## ArgoCD App of Apps Structure

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: monitoring-stack
  namespace: argocd
spec:
  project: default
  source:
    repoURL: <git-repo-url>
    path: argocd-apps/monitoring
    targetRevision: HEAD
  destination:
    server: https://kubernetes.default.svc
    namespace: monitoring
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

## Testing Strategy

### Pre-Migration Testing
1. Document current state metrics
2. Export Grafana dashboards
3. Backup configurations

### Post-Migration Testing
1. **Functional Tests**:
   - Loki log ingestion
   - Prometheus metrics collection
   - Grafana dashboard access
   - Alerting functionality

2. **Integration Tests**:
   - Service discovery
   - Cross-component communication
   - Data persistence

### Rollback Plan
1. Keep Helmfile configurations intact
2. Document ArgoCD application removal commands
3. Maintain backups of all configurations

## Timeline

| Week | Tasks |
|------|-------|
| Week 1 | Setup ArgoCD structure, Migrate Loki Stack |
| Week 2 | Migrate Prometheus Stack, Test integration |
| Week 3 | Migrate Grafana & Blackbox Exporter |
| Week 4 | Testing, Documentation, Cleanup |

## Success Criteria
- [ ] All services deployed via ArgoCD
- [ ] No data loss during migration
- [ ] All dashboards and alerts functional
- [ ] GitOps workflow established
- [ ] Documentation updated
- [ ] Team trained on ArgoCD operations

## Risk Mitigation
- **Risk**: Configuration incompatibility
  - **Mitigation**: Test in staging environment first

- **Risk**: Data loss during migration
  - **Mitigation**: Backup all persistent data

- **Risk**: Service downtime
  - **Mitigation**: Migrate one service at a time

## Next Steps
1. Review and approve plan
2. Set up ArgoCD application structure
3. Begin with Loki Stack migration
4. Proceed with remaining services

## Commands for Migration

### Remove from Helmfile (after ArgoCD deployment)
```bash
# List current releases
helm list -n monitoring

# Uninstall individual release (keep PVCs)
helm uninstall <release-name> -n monitoring --keep-history
```

### ArgoCD Commands
```bash
# Create application
kubectl apply -f argocd-apps/<service-name>/application.yaml

# Sync application
argocd app sync <app-name>

# Check status
argocd app get <app-name>
```