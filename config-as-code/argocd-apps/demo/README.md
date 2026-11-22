# demo cluster standalone Argo CD apps

Apps in this folder are applied directly with `kubectl apply -f <file>` against the
`hcm-demo` cluster's `argocd` namespace — there is no app-of-apps auto-syncing this
whole folder from git, so any new file here still needs to be applied manually once.

`airflow-app.yaml` is the one exception: `airflow-app-sync.yaml` is a file-scoped
app-of-apps (`directory.include: airflow-app.yaml`) that watches only that one file
and re-applies it automatically on every git change (see its own section below).

## Superset

On hcm-demo-v2, Superset is no longer deployed from this folder. It is
`helm/charts/argo-cd/analytics/superset-application.yaml`: the
`digit3/analytics/superset` chart from helm.digit.org, namespace `analytics`,
values from the `superset:` block of `environments/hcm-demo-v2-azure.yaml`, and
credentials in `superset-secret` (SOPS, `cluster-configs.secrets.generic`).
The upstream Apache Superset app that used to live here (`superset-app.yaml`,
namespace `superset`) was removed; it held no dashboards, charts, datasets or
connections. hcm-demo's own Superset never became ready (its pods crash-loop on
the placeholder DB passwords), so it had nothing to migrate either.

## ClickHouse

Also in `helm/charts/argo-cd/analytics/`, applied by hand like Superset:

1. `clickhouse-operator-application.yaml`: the ClickHouse Inc. operator
   (`digit3/analytics/clickhouse-operator`), namespace `clickhouse-operator`.
   Apply it first and wait for Healthy: it installs the CRDs and webhooks.
2. `clickhouse-application.yaml`: one ClickHouse server and one Keeper
   (`digit3/analytics/clickhouse`), namespace `analytics`, values from the
   `clickhouse:` block of the env file, passwords in `clickhouse-users` (SOPS,
   `cluster-configs.secrets.generic`).

Superset reaches it at
`clickhouse-clickhouse-headless.analytics.svc.cluster.local:8123` as user `app`.

## airflow-app.yaml

Adopts the pre-existing Airflow deployment (upstream chart `airflow.apache.org/airflow`,
`airflow` namespace) into Argo CD. That deployment was originally installed by a raw
`helm install airflow apache-airflow/airflow ...` on 2026-07-05, outside of git — this
Application brings it under git/Argo CD management without recreating any resources
(same release name `airflow`, same namespace, so Argo just adopts the existing objects
in place on first sync).

### Values were reconstructed from the live cluster, not from any prior git source

There was no existing values file to import from — the values block in
`airflow-app.yaml` was built by running `helm get values airflow -n airflow` and then
reconciling it against the *actually running* ConfigMap/Deployments, because several
fields had drifted from what Helm had on record (edited directly with `kubectl edit` /
`kubectl patch` at various points, never reflected back into a `helm upgrade`):

- `scheduler.resources` — live memory limits/requests were bumped to `4Gi`/`2Gi`
  (Helm's record still said `2Gi`/`1Gi`).
- `env` / `workers.env` `KAFKA_BROKER` — Helm's record pointed at
  `kafka.kafka-kraft.svc.cluster.local`, which doesn't resolve to any service. The
  real broker is `release-name-kafka.kafka-kraft.svc.cluster.local:9092` (the actual
  Kafka Helm release name in that namespace) — only the ConfigMap's
  `pod_template_file.yaml` had been hand-corrected to this.
- `ES_HOST` / `ELASTIC_USERNAME` / `ELASTIC_PASSWORD` and
  `IS_CENTRAL_INSTANCE_ENABLED` — present in the live worker pod template but absent
  from Helm's recorded values entirely.
- `workers.env` `TENANT_ID` — Helm's record said `mz`; the live, working value is
  `demo`.
- `config.webserver.base_url` — was `hcm-demo.digit.org`, corrected to
  `health-demo.digit.org` (see git history, 2026-09-17).

The values checked in here match the corrected, actually-working live state — not
whatever Helm happened to have on record. If you change any of the above, change it
here (and re-sync), not with a direct `kubectl edit`, or it'll drift again.

### Secrets are referenced by name, not pinned as literals

Unlike the Superset app above, Airflow's chart has first-class support for pointing at
pre-existing secrets (`fernetKeySecretName`, `apiSecretKeySecretName`, `jwtSecretName`,
`data.metadataSecretName`, `postgresql.auth.existingSecret`, and the generic `secret:`
list for `ELASTIC_PASSWORD`). All of these already existed in the `airflow` namespace
from the original install, so no secret values needed to be committed or placeholdered
— only the secret *names* appear in `airflow-app.yaml`. Same underlying risk as the
Superset postgres password (Argo CD renders via `helm template` with no cluster access,
so anything left unpinned regenerates randomly every sync) — it's just fully solved
here instead of worked around with a placeholder.

### Sync policy: selfHeal only, no prune (2026-09-18)

This app has a real, populated metadata Postgres and real running DAG history behind
it, so `syncPolicy.automated.prune` is deliberately left `false` — an unexpected
prune here (e.g. a field accidentally dropped from git) could delete live
Deployments/PVCs backing that data. `selfHeal: true` is enabled: once this file
changes and reaches the cluster (see `airflow-app-sync.yaml` below), drift between
the Application's spec and the live Deployments (like a `resources` bump) is applied
automatically, without ever pruning.

Before enabling `prune: true` as well, run a manual dry-run first to confirm nothing
unexpected would be deleted:

```bash
kubectl apply -f airflow-app.yaml
argocd app diff airflow   # or: argocd app sync airflow --dry-run
```

### `airflow-app-sync.yaml`: keeps this file's changes flowing from git automatically

Editing `airflow-app.yaml` alone does **not** reach the cluster — Argo CD only syncs
resources that some `Application` already knows to watch, and this folder isn't
watched by any app-of-apps. `airflow-app-sync.yaml` closes that gap for this one
file: it's a `directory`-source Application scoped to
`config-as-code/argocd-apps/demo/airflow-app.yaml` only (via `directory.include`),
with `syncPolicy.automated: {selfHeal: true, prune: false}`, so any git change to
`airflow-app.yaml` is re-applied to the `airflow` Application object automatically,
which then (per the selfHeal policy above) rolls out to the live Deployments.

It has no `resources-finalizer` of its own, so deleting `airflow-app-sync.yaml` (or its Application object) can never cascade
into deleting the `airflow` Application or the real resources behind it.

## hcm-demo-v2 bring-up

On the `azure-install-hcm-demo-v2` branch Airflow points at the v2 host
(`health-demo-v2.digit.org/airflow`).
A fresh cluster needs these before the first sync:

**Airflow**
1. `kubectl apply -f airflow-prereqs.yaml` (namespace + `airflow-logs-pvc`).
2. The secrets `airflow-app.yaml` references by name (`airflow-fernet-key`,
   `airflow-api-secret-key`, `airflow-jwt-secret`, `airflow-metadata`,
   `airflow-broker-url`, `airflow-postgresql`, `elasticsearch-credentials`) are
   rendered by cluster-configs from `cluster-configs.secrets.generic` in the v2
   SOPS secrets file, with hcm-demo's values.
3. `kubectl apply -f airflow-app-sync.yaml`; it applies `airflow-app.yaml` and
   keeps it in sync.

Unlike hcm-demo, the `/airflow` ingress is rendered by the chart
(`ingress.apiServer`) rather than created by hand.

**Superset**: see the Superset section above.
