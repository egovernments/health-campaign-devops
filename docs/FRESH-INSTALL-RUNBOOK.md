# HCM 2.1 fresh-install runbook (proven end-to-end 2026-08-23)

Every step below was executed and verified live on an empty cluster + empty database
(target cluster, tenant `mz`, db `<db_name>`): install → seed → HCMADMIN bootstrap →
public-domain smoke → unified CO-DELIVERY campaign to `created` with **5 projects persisted**.

## 0. Prerequisites
- A clone of this repo at a path **without spaces** — the deployer joins shell commands unquoted,
  so `~/eGov 2/...` breaks every helm call with `read …: is a directory`.
- Go (1.26 tested), helm (v4.2.4 tested), kubectl with the target cluster as current-context.
- helm 4 is nil-strict: this repo renders 70/70 release-chart services clean as of `8bcccaf9`.
  Re-verify after chart edits: render every service with
  `helm template -f <env> -f <env>-secrets --set image.tag=<pin> .` from each chart dir.

## 1. Environment file
Copy `config-as-code/environments/egov-demo.yaml` → `egov-<name>.yaml` (+ `-secrets.yaml`) and set:
- `global.domain` and the egov-config `domain` / `egov-services-fqdn-name`.
- `db-host` = **plain hostname, no `:port`** (a `:5432` suffix breaks the airflow migration's DNS
  lookup); `db-name`; `db-url`/`db-url-no-schema` with explicit `:5432`.
- `egov-filestore` section: real bucket name; secrets file: real db + S3 creds.
- **Non-central-instance cluster (bare Kafka topics, `public` schema):** flip every
  `central-instance-enabled: true` to `false` (24 sections; `console` may keep `true`) and
  project-factory's `IS_ENVIRONMENT_CENTRAL_INSTANCE` to `"false"`. Symptoms of missing this:
  project-factory refuses to boot; excel-ingestion queries schema `<tenant>.` and produces to
  `<tenant>-`-prefixed topics that nothing consumes — silently.
- `custom-js-injection` script URLs per environment (globalConfigs assets).

## 2. Deploy
```
cd deploy-as-code/deployer
go run main.go deploy -c -p -e egov-<name> "<comma-separated services from the release chart>"   # preview
go run main.go deploy -c -e egov-<name> "<same list>"                                             # apply
```
- Build the list from `config-as-code/product-release-charts/Health/dependancy_chart-health-demo-v2.1.yaml`
  (keep module order: backbone → authn-authz → core → …).
- If nginx-ingress/cert-manager are ALREADY live (reinstall case), exclude them — the env pins an
  old controller image and re-applying could break the existing LoadBalancer/DNS.
- `-c` applies cluster-configs (namespaces, secrets, egov-config); `-p` never touches the cluster.
- "Duplicate service found" warnings from the chart index are benign (last-wins, correct dirs).

## 3. Expected mid-state, then seed
~7 services crash-loop on an EMPTY database (egov-user, egov-enc-service, egov-workflow-v2,
worker-registry, inbox, individual, egov-malware-detection) — they need MDMS data and CANNOT go
green before seeding. All Flyway migrations complete regardless. Then:
```
cd seed-data/2.1 && export PG* creds && ./apply.sh          # or FROM_POD=1 with a kubeconfig
kubectl -n egov rollout restart deploy/mdms-v2 deploy/project-factory
kubectl -n backbone exec deploy/redis -- redis-cli DEL messages computedMessages
```
The loopers self-heal within minutes (delete their pods to skip the backoff).

## 4. HCMADMIN bootstrap
```
kubectl -n egov create secret generic hcmadmin-seed --from-literal=password='<pass>'
cd config-as-code/helm/charts/core-services/egov-user
helm template -f <env-file> -f egov-user-values.yaml --set hcmSeed.enabled=true --set image.tag=<pin> . \
  | <filter kind: Job> | kubectl -n egov apply -f -
```

## 5. Boundary data (runtime, by design not in the seed)
Load hierarchies + trees via boundary-service APIs or the boundary excel flow. Minimal smoke tree:
hierarchy-definition `_create`, boundary `_create`, boundary-relationships `_create` per node.

## 6. Verification gates (all passed 2026-08-23)
1. `POST /user/oauth/token` through the public domain issues a token for HCMADMIN.
2. Localization + MDMS serve the seeded data (5 active projectTypes, seeded labels).
3. All API ingress paths back onto `gateway:8080`.
4. Unified campaign e2e: draft → excel-ingestion `generate/_init` (`unified-console`, needs
   `referenceId`+`referenceType=campaign`) → fill Boundary List target columns (ALL mandatory) →
   filestore upload → `project-type/update` action=create (startDate must be a FUTURE date) →
   status `created` → `SELECT count(*) FROM project WHERE referenceid='<campaign number>'` > 0.

## 7. Image pins vs demo (measured 2026-08-24)
Demo's builds come from `health-campaign-devops@azure-install-hcm-demo:config-as-code/environments/hcm-demo-azure.yaml`.
Compared service-by-service against that file, with Docker Hub `last_updated` as the tie-breaker:
50 of 57 comparable services are identical. Of the 7 that differ:

| service | this chart | demo | decision |
|---|---|---|---|
| project-factory | `master-32ff216` | `master-32ff216` | adopted demo (2026-08-21 11:13) |
| excel-ingestion | `master-32ff216` | `master-32ff216` | adopted demo (2026-08-21 11:23) |
| airflow-trigger-service | `master-38dc577` | `master-38dc577` | adopted demo; it is the MERGED form of the `HCMPRE-4161-airflowTrigger` branch this chart used to pin |
| dashboard-ui | `master-4e0e7fd` | `master-4e0e7fd` **live** | already identical (see correction) |
| payments-ui | `master-2376f89` | `master-2376f89` **live** | already identical (see correction) |
| transformer | `transformer-final-2.1-2c59d3b` | same **live** | already identical (see correction) |
| workbench-ui | `master-2376f89` | `master-b40c93b` **live** | demo is 1 day AHEAD — adopt |

The two `master-38dc577` → `master-32ff216` moves are strict fast-forwards: `git merge-base --is-ancestor`
confirms `38dc577` is an ancestor of `32ff216`, and that `b9c634e` — the commit the campaign/attendance e2e
depends on — is an ancestor of both. `32ff216` adds PR #2154 (attendance-register bugfixes).
`plan-service` and `resource-generator` pin `master-b912a1c`, matching demo; the live `v1.0.2-*` tags seen on
a hand-built cluster are the drift, not the chart.

### CORRECTION 2026-08-24 — `hcm-demo-azure.yaml` IS NOT A PROXY FOR DEMO'S LIVE STATE
The first version of this table claimed four services were "deliberately ahead of demo" (dashboard-ui by 4
months, payments-ui by 3, workbench-ui by 3, transformer by 6 weeks). **That was wrong**, and it was wrong
because it compared against demo's env file instead of demo's cluster. Read live from the demo cluster with
`KUBECONFIG=~/Downloads/readonly-kubeconfig.yaml` (context `readonly-context`):

```
dashboard-ui  demo egovio/dashboard-ui:master-4e0e7fd   == target      IDENTICAL
payments-ui   demo egovio/payments-ui:master-2376f89    == target      IDENTICAL
transformer   demo transformer-final-2.1-2c59d3b        == target      IDENTICAL
workbench-ui  demo master-b40c93b  vs target master-2376f89   demo AHEAD by ~1 day
```

Only **2 of 60** live images differ at all: `workbench-ui` (demo ahead) and `redis` (demo runs 7.2.4 while
BOTH repos declare 3.2 — demo's pod is an undeclared manual bump, so the target is the compliant side).

Why the file misleads: `hcm-demo-azure.yaml:167` still pins `workbench-ui: master-9fcd8db`, but demo's real
pin lives in the tenant overlay `demo-tenant.yaml`. The env file is stale for any service overridden there.

**Rule:** verify demo's state against the demo CLUSTER via the readonly kubeconfig. Use `hcm-demo-azure.yaml`
only for what demo *declares*, never for what it *runs*, and say which one you measured.

## 8. UPGRADE-IN-PLACE TRAP: client-side apply silently drops env vars (measured 2026-08-24)
The deployer applies with client-side `kubectl apply`. Re-deploying a service whose Deployment was created
from an OLDER chart can produce a live spec with FEWER env vars than the manifest that was applied — the
strategic-merge of the `env` list loses entries. Measured on the 3-service pin bump:

| service | manifest applied | live spec after apply | lost |
|---|---|---|---|
| excel-ingestion | 102 vars | 98 | `SPRING_DATASOURCE_URL/USERNAME/PASSWORD/DRIVER_CLASS_NAME` → Spring fell back to `localhost:5432`, `Connection refused`, pod never became ready |
| project-factory | 249 vars | 247 | `EGOV_MDMS_V1_SEARCH_ENDPOINT`, `LOCALIZATION_MODULE` — pod stayed 1/1 GREEN, so this class is invisible to health checks |
| airflow-trigger-service | 13 vars | 13 | none |

This is NOT a chart defect: the chart renders all 102/249 correctly (`helm template` is deterministic — 5
consecutive renders gave identical output), and the `kubectl.kubernetes.io/last-applied-configuration`
annotation contained every var. Same family as the `worker-registry` value→valueFrom flip that needed
delete+recreate.

**Fix / gate.** After ANY re-deploy onto an existing cluster:
1. `kubectl -n egov apply --server-side --force-conflicts -f <rendered deployment>` — this restored both
   services to full env with no downtime, and is the preferred remedy over delete+recreate.
2. Then PROVE it: capture each container's env-var name set before and after and diff them. A green pod is
   not evidence — project-factory above lost 2 vars while reporting healthy.

## Known cosmetics / open
- kibana can wedge at readiness 503 while the fresh es-cluster finishes its first bootstrap —
  recreate the kibana pod once Elasticsearch is settled and it reports available in ~3 minutes
  (verified live).
- Duplicate env names across charts: RESOLVED in `82c01491` (all 61 removed; proven behavior-neutral
  by comparing every container's effective last-wins env before/after across all 68 services).
