# demo cluster standalone Argo CD apps

Apps in this folder are applied directly with `kubectl apply -f <file>` against the
`hcm-demo` cluster's `argocd` namespace — there is no app-of-apps auto-syncing this
folder from git yet, so any new file here also needs to be applied manually once.

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
