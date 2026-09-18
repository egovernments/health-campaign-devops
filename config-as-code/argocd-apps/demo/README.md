# demo cluster standalone Argo CD apps

Apps in this folder are applied directly with `kubectl apply -f <file>` against the
`hcm-demo` cluster's `argocd` namespace — there is no app-of-apps auto-syncing this
whole folder from git, so any new file here (or edits to `superset-app.yaml`) still
needs to be applied manually once.

`airflow-app.yaml` is the one exception: `airflow-app-sync.yaml` is a file-scoped
app-of-apps (`directory.include: airflow-app.yaml`) that watches only that one file
and re-applies it automatically on every git change (see its own section below).
It deliberately does **not** include `superset-app.yaml` — that file has placeholder
secrets that must never be auto-reapplied (see the Superset section below) — so
Superset stays manual-only.

## superset-app.yaml

Deploys Apache Superset (upstream chart `apache.github.io/superset`) into its own
`superset` namespace, exposed at `https://superset.hcm-demo.digit.org` (Superset does
not reliably support being served from a subpath, so a dedicated subdomain is used
instead of `hcm-demo.digit.org/superset`).

Requires the DNS record `superset.hcm-demo.digit.org` to point at the same ingress
load balancer IP as `hcm-demo.digit.org` before cert-manager can issue the TLS cert.

### Required secret (pre-created in-cluster, intentionally not committed to git)

Must exist in the `superset` namespace before/when the Application syncs:

- `superset-app-secrets` — key `SUPERSET_SECRET_KEY` (Flask secret key, `openssl rand -base64 42`),
  wired in via `envFromSecrets`.

```bash
kubectl create secret generic superset-app-secrets -n superset \
  --from-literal=SUPERSET_SECRET_KEY="$(openssl rand -base64 42 | tr -d '\n')"
```

### Postgres/Redis passwords (placeholders in git — READ THIS before reapplying)

The bundled Postgres has no `existingSecret` indirection for the *app side* of its
DB connection: `postgresql.auth.password` / `database.password` are rendered as
literal strings into the pods' env, so they can't be secret-refs the way you'd
expect. They also can't be left unset, because Argo CD renders this chart via
`helm template` with no live cluster access — the subchart's `lookup()`-based
"reuse the existing password" logic always misses in that mode, so an unset
password gets **regenerated randomly on every single sync**, orphaning it from
whatever password the already-initialized data volume actually has (this broke
the deployment once already — see git history).

So the password *must* be pinned as a literal. `postgresql.auth.postgresPassword`,
`postgresql.auth.password`, and `database.password` (the last two must match
each other) are checked into this file as `REPLACE_WITH_REAL_VALUE` rather than
real secrets, because this repo's usual secret-encryption path (sops against the
`hcm-demo-kv` Azure Key Vault, same as `environments/dhis2-secrets.yaml`) wasn't
reachable when this file was authored. **The live Application in the cluster has
real values already applied and running** — git and the cluster are
intentionally out of sync on just these three fields.

If you ever need to recreate this Application from git alone: generate two new
random passwords, substitute them for all three `REPLACE_WITH_REAL_VALUE`
placeholders, `kubectl apply` the file, then — because the data volume will be
fresh — the values will actually take effect cleanly (no orphaned-password
problem on a brand new volume). Ideally, migrate this to a real sops-encrypted
values file instead of leaving it as a placeholder long-term.

### Admin user

`init.createAdmin` is set to `false` so no admin password is ever templated into the
Application spec. After the first successful sync, create the admin user directly in
the running pod:

```bash
kubectl exec -n superset deploy/superset -it -- superset fab create-admin \
  --username admin --firstname Superset --lastname Admin \
  --email <real-email> --password '<choose-a-strong-password>'
```

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

It intentionally excludes `superset-app.yaml` and has no `resources-finalizer` of its
own, so deleting `airflow-app-sync.yaml` (or its Application object) can never cascade
into deleting the `airflow` Application or the real resources behind it.
