# Monitoring Stack - ArgoCD Migration

## Overview
This directory contains ArgoCD Application manifests for deploying the monitoring stack.

## Components
1. **loki-stack-app.yaml** - Loki with TSDB configuration for log aggregation
2. **prometheus-stack-app.yaml** - Prometheus for metrics collection
3. **grafana-app.yaml** - Grafana for visualization
4. **blackbox-exporter-app.yaml** - Blackbox exporter for endpoint monitoring
5. **monitoring-stack-app.yaml** - Parent app to manage all monitoring apps

## Migration Steps

### Step 1: Deploy the Parent Application
```bash
kubectl apply -f monitoring-stack-app.yaml
```

This will create the parent application that manages all monitoring components.

### Step 2: Verify Applications
```bash
kubectl get applications -n argocd | grep -E "loki|prometheus|grafana|blackbox|monitoring"
```

### Step 3: Check Sync Status
```bash
argocd app get monitoring-stack
argocd app get loki-stack
argocd app get kube-prometheus-stack
argocd app get grafana
argocd app get blackbox-exporter
```

### Step 4: Manual Sync (if needed)
```bash
argocd app sync monitoring-stack
```

## Rollback from Helmfile

Once ArgoCD applications are verified to be working:

### Step 1: List Helm Releases
```bash
helm list -n monitoring
```

### Step 2: Backup Current State
```bash
helm get values loki-stack -n monitoring > loki-stack-backup.yaml
helm get values kube-prometheus-stack -n monitoring > prometheus-backup.yaml
helm get values grafana -n monitoring > grafana-backup.yaml
helm get values blackbox -n monitoring > blackbox-backup.yaml
```

### Step 3: Uninstall Helm Releases
⚠️ **WARNING**: Only do this after confirming ArgoCD apps are healthy

```bash
# Keep PVCs to preserve data
helm uninstall loki-stack -n monitoring --keep-history
helm uninstall kube-prometheus-stack -n monitoring --keep-history
helm uninstall grafana -n monitoring --keep-history
helm uninstall blackbox -n monitoring --keep-history
```

## Important Notes

### Loki TSDB Configuration
- Uses Azure Storage Container: `loki`
- Storage Account: `whoafrolokisaprd`
- Schema: v13 with TSDB store
- Retention: 30 days (720h)

### Persistent Storage
- Loki: 30Gi PVC
- Prometheus: 30Gi PVC
- Grafana: 10Gi PVC

### Access URLs
- Grafana: https://campaigns.afro.who.int/grafana
- Prometheus: Internal service at `kube-prometheus-stack-prometheus:9090`
- Loki: Internal service at `loki-stack:3100`

## Troubleshooting

### Check Pod Status
```bash
kubectl get pods -n monitoring
```

### Check Loki TSDB
```bash
kubectl exec -it loki-stack-0 -n monitoring -- grep "store: tsdb" /etc/loki/loki.yaml
```

### View Logs
```bash
kubectl logs -n monitoring loki-stack-0
kubectl logs -n monitoring prometheus-kube-prometheus-stack-prometheus-0
```

### Force Sync
```bash
argocd app sync <app-name> --force
```

## Rollback to Helmfile (Emergency)

If needed to rollback to Helmfile:

1. Delete ArgoCD applications:
```bash
kubectl delete -f monitoring-stack-app.yaml
```

2. Reinstall using Helmfile:
```bash
cd /Users/nikhil/Desktop/egov/azure/health-campaign-devops/config-as-code/helm/charts/monitoring
helmfile -e env sync -f monitoring-helmfile.yaml.gotmpl
```

## Contact
For issues or questions, please contact the DevOps team.