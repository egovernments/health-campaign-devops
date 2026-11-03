# hcm-demo → hcm-demo-v2 snapshot and restore runbook

Moves the live demo's data into the parallel HCM v2.2 environment. Written to be
run **twice**: once to load the environment for validation, and again at cutover
to pick up everything written to the live demo in between.

| | source | target |
|---|---|---|
| kube context | `hcm-demo` | `hcm-demo-v2` |
| region | Central US | Central India |
| resource group | `hcm-demo-rg` | `hcm-demo-v2-rg` |
| Postgres | `hcm-demo-server-v2` / `healthdemo` | `hcm-demo-v2-server` / `healthdemo` |
| filestore account | `egovfilestorehcm` | `egovfilestorehcmv2` |
| domain | `health-demo.digit.org` | `health-demo-v2.digit.org` |

The live environment is **not** modified by this runbook, with one explicitly
agreed exception called out in step 2. Everything else against the source is a
read.

---

## 0. Before you start

The target cluster must already be running Elasticsearch and have an empty
`healthdemo` database — i.e. the platform is bootstrapped from
`azure-install-hcm-demo-v2` but carries no data yet.

```sh
kubectl --context hcm-demo-v2 -n es-cluster get pods
az postgres flexible-server db show -g hcm-demo-v2-rg -s hcm-demo-v2-server -d healthdemo
```

Record the snapshot moment — every step below should describe the same point in
time, or the DSS aggregates will not reconcile against the transactional data:

```sh
export SNAP=snap-$(date -u +%Y%m%d-%H%M)
echo "$SNAP"
```

---

## 1. Elasticsearch — the DSS data

~21.7 GB across three data nodes. This is what backs the DSS dashboards, so it
is the part that most needs to arrive intact.

### 1.1 Why snapshot rather than reindex

`repository-azure` ships as a bundled module in Elasticsearch 8.11.3 (it does
not appear in `_cat/plugins`, which lists only true plugins — check
`_nodes/plugins?filter_path=nodes.*.modules.name`). The snapshot API preserves
mappings, settings and aliases exactly, and the second run is incremental, which
is what makes the cutover window short.

### 1.2 Grant the source cluster write access (the agreed exception)

Azure repository credentials can only be supplied through the Elasticsearch
keystore. Note that `/usr/share/elasticsearch/config` is **not** a mounted
volume on these pods — only `config/certs` is — so keystore entries live in the
container's ephemeral layer and disappear on any pod restart. The change is
self-reverting; nothing needs cleaning up afterwards.

```sh
KEY=$(az storage account keys list -g hcm-demo-v2-rg \
        -n egovfilestorehcmv2 --query "[0].value" -o tsv)

for p in elasticsearch-master-0 elasticsearch-master-1 elasticsearch-master-2 \
         elasticsearch-data-0 elasticsearch-data-1 elasticsearch-data-2; do
  kubectl --context hcm-demo -n es-cluster exec "$p" -c elasticsearch -- \
    sh -c "printf 'egovfilestorehcmv2' | /usr/share/elasticsearch/bin/elasticsearch-keystore add -x -f azure.client.default.account \
        && printf '%s' '$KEY' | /usr/share/elasticsearch/bin/elasticsearch-keystore add -x -f azure.client.default.key"
done
```

Reload without restarting (Azure client settings are reloadable):

```sh
kubectl --context hcm-demo -n es-cluster exec elasticsearch-data-0 -c elasticsearch -- \
  sh -c 'curl -sk -u elastic:$ELASTIC_PASSWORD -XPOST \
    "https://127.0.0.1:9200/_nodes/reload_secure_settings?pretty"'
```

Every node must report success. A node missing the credential fails the snapshot
partway through.

### 1.3 Register the repository and snapshot

```sh
kubectl --context hcm-demo -n es-cluster exec elasticsearch-data-0 -c elasticsearch -- \
  sh -c 'curl -sk -u elastic:$ELASTIC_PASSWORD -XPUT \
    "https://127.0.0.1:9200/_snapshot/hcm_demo_repo?pretty" \
    -H "Content-Type: application/json" -d "{
      \"type\": \"azure\",
      \"settings\": { \"container\": \"es-snapshots\", \"base_path\": \"hcm-demo\", \"client\": \"default\" }
    }"'
```

Verify the repository before trusting it — this writes and removes a probe blob:

```sh
kubectl --context hcm-demo -n es-cluster exec elasticsearch-data-0 -c elasticsearch -- \
  sh -c 'curl -sk -u elastic:$ELASTIC_PASSWORD -XPOST \
    "https://127.0.0.1:9200/_snapshot/hcm_demo_repo/_verify?pretty"'
```

Take the snapshot. `indices` deliberately excludes system indices (`.`-prefixed)
— those belong to the target cluster's own security and Kibana state and must
not be overwritten:

```sh
kubectl --context hcm-demo -n es-cluster exec elasticsearch-data-0 -c elasticsearch -- \
  sh -c "curl -sk -u elastic:\$ELASTIC_PASSWORD -XPUT \
    'https://127.0.0.1:9200/_snapshot/hcm_demo_repo/$SNAP?wait_for_completion=false&pretty' \
    -H 'Content-Type: application/json' -d '{
      \"indices\": \"*,-.*\",
      \"include_global_state\": false
    }'"
```

Poll until `state` is `SUCCESS`:

```sh
kubectl --context hcm-demo -n es-cluster exec elasticsearch-data-0 -c elasticsearch -- \
  sh -c "curl -sk -u elastic:\$ELASTIC_PASSWORD \
    'https://127.0.0.1:9200/_snapshot/hcm_demo_repo/$SNAP/_status?pretty'" \
  | grep -E '"state"|"done"|"total"'
```

Treat anything other than `SUCCESS` as a stop. `PARTIAL` means shards were
missed and the DSS data would land incomplete.

### 1.4 Restore onto the target

Register the same repository read-only, so the new cluster can never write into
the source's snapshot history:

```sh
KEY=$(az storage account keys list -g hcm-demo-v2-rg \
        -n egovfilestorehcmv2 --query "[0].value" -o tsv)

for p in elasticsearch-master-0 elasticsearch-master-1 elasticsearch-master-2 \
         elasticsearch-data-0 elasticsearch-data-1 elasticsearch-data-2; do
  kubectl --context hcm-demo-v2 -n es-cluster exec "$p" -c elasticsearch -- \
    sh -c "printf 'egovfilestorehcmv2' | /usr/share/elasticsearch/bin/elasticsearch-keystore add -x -f azure.client.default.account \
        && printf '%s' '$KEY' | /usr/share/elasticsearch/bin/elasticsearch-keystore add -x -f azure.client.default.key"
done

kubectl --context hcm-demo-v2 -n es-cluster exec elasticsearch-data-0 -c elasticsearch -- \
  sh -c 'curl -sk -u elastic:$ELASTIC_PASSWORD -XPOST \
    "https://127.0.0.1:9200/_nodes/reload_secure_settings?pretty"'

kubectl --context hcm-demo-v2 -n es-cluster exec elasticsearch-data-0 -c elasticsearch -- \
  sh -c 'curl -sk -u elastic:$ELASTIC_PASSWORD -XPUT \
    "https://127.0.0.1:9200/_snapshot/hcm_demo_repo?pretty" \
    -H "Content-Type: application/json" -d "{
      \"type\": \"azure\",
      \"settings\": { \"container\": \"es-snapshots\", \"base_path\": \"hcm-demo\", \"client\": \"default\", \"readonly\": true }
    }"'
```

Restore:

```sh
kubectl --context hcm-demo-v2 -n es-cluster exec elasticsearch-data-0 -c elasticsearch -- \
  sh -c "curl -sk -u elastic:\$ELASTIC_PASSWORD -XPOST \
    'https://127.0.0.1:9200/_snapshot/hcm_demo_repo/$SNAP/_restore?wait_for_completion=false&pretty' \
    -H 'Content-Type: application/json' -d '{
      \"indices\": \"*,-.*\",
      \"include_global_state\": false
    }'"
```

**On the cutover run** the indices already exist and the restore will be
rejected. Delete them first — on the target only, and never with a bare `*`:

```sh
kubectl --context hcm-demo-v2 -n es-cluster exec elasticsearch-data-0 -c elasticsearch -- \
  sh -c 'curl -sk -u elastic:$ELASTIC_PASSWORD -XDELETE "https://127.0.0.1:9200/demo-*,plan-*"'
```

### 1.5 Verify

Compare document counts per index between the two clusters. They should match
exactly for anything not still being written:

```sh
for c in hcm-demo hcm-demo-v2; do
  echo "== $c"
  kubectl --context $c -n es-cluster exec elasticsearch-data-0 -c elasticsearch -- \
    sh -c 'curl -sk -u elastic:$ELASTIC_PASSWORD \
      "https://127.0.0.1:9200/_cat/indices/demo-*?h=index,docs.count&s=index"'
done
```

---

## 2. PostgreSQL — the transactional data

The source server has **no public endpoint** and is VNet-injected, so the dump
must run from inside the source cluster. `geoRedundantBackup` is disabled on it,
which is why Azure's own geo-restore is not an option and this is a logical
dump.

Run a throwaway pod in the source cluster — it touches no application workload:

```sh
kubectl --context hcm-demo -n egov run pgdump-$RANDOM --rm -i --restart=Never \
  --image=postgres:15 --env PGPASSWORD="$SRC_DB_PASSWORD" -- \
  pg_dump -h hcm-demo-server-v2.postgres.database.azure.com \
          -U healthegovdemo -d healthdemo -Fc --no-owner --no-acl \
  > healthdemo-$SNAP.dump
```

Keep `-Fc` (custom format): it restores in parallel and lets you skip objects if
a single table misbehaves. Check the dump is a real archive, not an error page:

```sh
pg_restore -l healthdemo-$SNAP.dump | head
ls -lh healthdemo-$SNAP.dump
```

Restore into the target, again from inside its own VNet:

```sh
kubectl --context hcm-demo-v2 -n egov run pgrestore-$RANDOM --rm -i --restart=Never \
  --image=postgres:15 --env PGPASSWORD="$TGT_DB_PASSWORD" -- \
  pg_restore -h hcm-demo-v2-server.postgres.database.azure.com \
             -U healthegovdemo -d healthdemo --no-owner --no-acl -j 4 \
  < healthdemo-$SNAP.dump
```

Expect noise about extensions and roles that already exist; those are harmless.
Errors mentioning a *table* or *constraint* are not — stop and read them.

Sanity-check a few row counts against the source before moving on.

---

## 3. Filestore blobs

Copy the containers the filestore actually writes to. `egov-rainmaker` is the
`fixed-bucketname`; `egov-quarantine` is where clamav moves infected uploads.

```sh
SRC_KEY=$(az storage account keys list -g hcm-demo-rg -n egovfilestorehcm --query "[0].value" -o tsv)
TGT_KEY=$(az storage account keys list -g hcm-demo-v2-rg -n egovfilestorehcmv2 --query "[0].value" -o tsv)

for c in egov-rainmaker egov-quarantine; do
  az storage blob copy start-batch \
    --source-account-name egovfilestorehcm --source-account-key "$SRC_KEY" \
    --source-container "$c" \
    --account-name egovfilestorehcmv2 --account-key "$TGT_KEY" \
    --destination-container "$c"
done
```

This is server-side and asynchronous. Confirm both sides agree before calling it
done:

```sh
for c in egov-rainmaker egov-quarantine; do
  echo "$c  src=$(az storage blob list --account-name egovfilestorehcm --account-key "$SRC_KEY" -c "$c" --query "length(@)" -o tsv)" \
       "tgt=$(az storage blob list --account-name egovfilestorehcmv2 --account-key "$TGT_KEY" -c "$c" --query "length(@)" -o tsv)"
done
```

---

## 4. In-cluster datastores

These live on PVCs rather than managed services, and each is a separate small
dump. None carry DSS data, so they can follow the main restore.

| what | where | why it matters |
|---|---|---|
| Superset metadata | `superset/data-superset-postgresql-0` (20 Gi) | dashboards, charts, saved queries |
| DHIS2 | `dhis2/dhis2-postgresql-1` (20 Gi) | DHIS2 instance data |
| Airflow metadata | `airflow/data-airflow-postgresql-0` (8 Gi) | DAG run history; safe to skip if a clean slate is acceptable |
| Grafana | `monitoring/grafana` (10 Gi) | dashboards — prefer exporting via the API |
| JupyterHub | `jhub/claim-*` (4 × 25 Gi) | user notebooks |

Pattern for each in-cluster Postgres:

```sh
kubectl --context hcm-demo -n superset exec superset-postgresql-0 -- \
  pg_dump -U superset -d superset -Fc > superset-$SNAP.dump

kubectl --context hcm-demo-v2 -n superset exec -i superset-postgresql-0 -- \
  pg_restore -U superset -d superset --no-owner --clean --if-exists < superset-$SNAP.dump
```

---

## 5. Cutover

Only after HCM v2.2 is validated on the new environment, and only on explicit
confirmation.

1. Freeze writes to the live demo, or accept the delta and announce it.
2. Re-run sections 1–4. Elasticsearch is incremental on the second pass, so the
   window is dominated by the Postgres dump, not the index copy.
3. Repoint DNS from `health-demo.digit.org` to the new environment's ingress and
   let cert-manager issue the certificate.
4. Merge the GitOps branch so the names converge:
   `git checkout azure-install-hcm-demo && git merge azure-install-hcm-demo-v2`
5. Leave the old environment running until the new one has been live through a
   full working day. It is the rollback.

### Rollback

Nothing in steps 1–4 writes to the live environment, so rollback before cutover
is simply "keep using `health-demo.digit.org`". After DNS is repointed, rollback
is repointing it back — which is why the old environment stays up.

---

## Notes

- `backbone`, `monitoring-stack` and `clamav` are sourced from the
  `HCM-WHO-AFRO` fork, not from this repo's branch. The new cluster reads them
  read-only. Any v2.2 change needed there requires a branch in that fork.
- The secrets file is SOPS-encrypted against Key Vault `hcm-demo-kv`, which is
  in the *old* resource group. The new cluster's ArgoCD needs read access to
  that vault's key, or the secrets must be re-encrypted against
  `hcm-demo-v2-kv`.
- The UI global configs are served from `hcm-demo-assets.s3.ap-south-1.amazonaws.com`
  and hardcode the environment's domain. Confirm whether the v2.2 frontend needs
  its own copies pointing at `health-demo-v2.digit.org`, or the new environment's
  UI will call back to the old one.
