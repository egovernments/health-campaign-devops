# HCM 2.1 seed data (tenant `mz`) — sourced from hcm-demo

This bundle carries the runtime data a fresh HCM 2.1 one-click install needs **beyond** the Helm charts
and service config. The authoritative files are **exported from the hcm-demo reference environment
(tenant `demo`) and rewritten to tenant `mz`** (demo→mz), so a fresh install reproduces demo.

## Authoritative demo-sourced files (applied by `apply.sh`)

| File | Rows | Source | Notes |
|---|---|---|---|
| `19-demo-mdms-schema-def-mz.sql` | 311 | demo `eg_mdms_schema_definition` | MDMS schema defs; apply first. Re-verified 2026-08-20 against live demo: **0 drift**. |
| `21-demo-mdms-data-mz.sql` | 6,284 | demo `eg_mdms_data` via `mdms-v2/v2/_search` | ALL MDMS masters (access control, project types, targetConfigs, adminSchema, ChecklistTemplates, service registry, …). Excludes runtime-generated `FormConfig`/`TransformedFormConfig`/`AppConfigCache`/`AppFlowConfig` and the 295 per-campaign `airflow-configs.campaign-report-config` rows (see below). |
| `22-demo-products-mz.sql` | 109 products + 99 variants | demo `product` + `product_variant` | The product catalogue campaigns reference (incl. CO-DELIVERY's `PVAR-2026-07-06-000909/910`). **Not re-verified on 2026-08-20** — demo's `product` API requires auth; this remains the 2026-08-20 01:14 pgAdmin CSV snapshot. |
| `20-demo-localization-mz.sql` | 191,106 | demo localization API | 76 modules × en/pt/fr_MZ (75,294 / 57,796 / 58,016). See the breakdown below. |

### What `20` contains, and why

| Family | Rows | In seed? | Reason |
|---|---|---|---|
| 25 reusable UI-label modules | 79,401 | ✅ | Static authored labels (unchanged — 0 drift vs live demo). |
| 49 `hcm-base-<module>-<projectType>` | 107,212 | ✅ **new** | App-config label **templates**. project-factory `campaignUtils.ts:3173-3175` builds `baseKey = hcm-base-<module>-<projectType>` and `updatedKey = hcm-<module>-<campaignNumber>`, then `upsertLocalisations()` **copies base → per-campaign** at campaign creation. Nothing writes the base rows at runtime (they originate as committed JSON in DIGIT-Frontend `health/configs/Localisations/`), and a missing base module fails **silently** (`catch → continue`; an empty message list yields an empty copy loop). Without these, every campaign created on a fresh install renders **raw label codes** in the field-worker app. |
| `hcm-dss` + `rainmaker-hcm-dss` static labels | 4,493 | ✅ **new** | DSS dashboard labels, requested by `health-dss/src/Module.js:16`. |
| `rainmaker-hcm-dss` `DSS_TB_*` / `COMMON_MASTERS_*` | 28,800 | ❌ | Identity mappings (code suffix == message) generated from uploaded boundary place names. |
| `hcm-boundary-*` | 185,944 | ❌ | Regenerated unconditionally on boundary upload (`boundaryUtils.ts:512-519`) and specific to demo's own hierarchies. Also would breach the localization row guard. |
| `hcm-<module>-CMP-*` (1,965 modules) | 4,489,558 | ❌ | Per-campaign copies, regenerated from the `hcm-base-*` templates above. |

> **`20` now begins with a required DDL pre-step.** egov-localization migration `V20170502122717` creates
> `message.message` as `varchar(500)`, but demo itself stores messages up to **543** characters (16 rows:
> `hcm-admin-schemas` README text and `digit-ui` privacy-policy text, in pt/fr). Without widening, a fresh
> install aborts with `ERROR: value too long for type character varying(500)`. The file widens the column to
> `varchar(1000)` inside an idempotent guarded `DO $$` block (widening only; no data loss). **This affected
> the previous revision of this bundle too** — it was not caught earlier because the throwaway validation DB
> did not reproduce the real column width.

### Per-campaign rows: excluded vs retained

`airflow-configs.campaign-report-config` (295 rows) is **excluded**: every `uniqueIdentifier` embeds a demo
campaign number (e.g. `CMP-2026-08-20-004186.adverse_reactions_report.17:50:00+0530.DAILY`), spanning 50
demo campaigns that cannot exist on a fresh cluster — the seed writes no campaign table at all, so 50/50
references dangle by construction. The population also **grew during the working day** (287 → 295 between
two pulls hours apart), which makes it an operational accretion log rather than authored master data.
Excluding it costs no capability: the schema definition survives in `19`, and the `mdms-v2/v2/_create/...`
access-control action plus its `CAMPAIGN_MANAGER` role grant survive in `21`.

**Known inconsistency, deliberately retained:** 72 other rows still embed a `CMP-*` campaign number —
64 `HCM-ADMIN-CONSOLE.NewFormConfig`, 6 `NewApkConfig`, 1 `FormConfigTemplate`, 1 `NewAppConfig`. By the
same test they would also be excluded, but unlike the airflow rows it has **not** been verified that
dropping them costs no capability, and the governing rule for this bundle is "mirror demo unless there is a
confirmed reason not to". They are believed inert (`getTemplateModules` filters on `project: <campaignType>`,
so campaign-keyed rows never match). Open item.

Still needed for the non-MDMS/non-product/non-localization parts (kept as-is, hand-built):
`03-workflow.sql` (eg_wf_* business services), `04-pgr.sql` (PGR + departments), `06-hierarchyschema-handover.sql`
(campaign HierarchySchema repoint — largely redundant now that 21 carries HierarchySchema), `07-project-department-nullable.sql`
(project.department ALTER), `08-sso-identityproviders.TEMPLATE.sql` (SSO, environment-specific template).

## Superseded (NOT applied — kept for history)
`01-mdms`, `02-accesscontrol`, `05-localization`, `09-project-types-active`, `10-localization-ui-labels-mirror`,
`11-mdms-adminschema-checklist-mirror`, `12-localization-labels-full-mirror` — all replaced by the complete
demo-sourced `19`/`20`/`21`.

## demo→mz substitution applied to the demo export
`tenantid` `demo`→`mz`; locales `en_DEMO`/`pt_DEMO`/`fr_DEMO`→`en_MZ`/`pt_MZ`/`fr_MZ`; `"demo"` value→`"mz"`;
`demo-`→`mz-` (index/topic prefixes); `demo.`→`mz.` (schema qualifiers); a `uniqueidentifier` that is exactly
`demo`→`mz`. English words (`demography`…) and mixed-case `Demo` are preserved.

For localization the substitution is **tenant and locale only** — `module`, `code` and `message` are carried
verbatim (confirmed by diffing the previous seed against the live source: 0 message differences).

> Deliberately **not** a blanket `DEMO`→`MZ`: the literal `INSIDEMONITORING` contains the substring `DEMO`
> and appears 44+ times across MDMS payloads and as the `hcm-base-insidemonitoring-polio` module. A blanket
> rule would silently corrupt it to `INSIMZNITORING`.

This rule was not invented — it was reverse-engineered from the previously committed seed and validated at
**6,565/6,565 exact data matches** before being re-applied to the fresh pull.

## Idempotency and convergence (per file)

| File | Conflict key | Behaviour |
|---|---|---|
| `19` | `(tenantid, code)` | **DO UPDATE** — definition, description, isactive, audit |
| `20` | `(tenantid, locale, module, code)` | **DO UPDATE** — message, audit |
| `21` | `(tenantid, schemacode, uniqueidentifier)` | **DO UPDATE** — data, isactive, audit (`id` is never updated; an existing row keeps its own, since `uk_eg_mdms_data` is `UNIQUE(id)`) |
| `22` | `(id)` | `DO NOTHING` |

`19`/`20`/`21` were `DO NOTHING` until 2026-08-20. **That was a real defect on any non-empty cluster.**
`DO NOTHING` can add a row but can never correct one, so a tenant that already had a label or a master with
a stale value kept it forever and could never be brought back in line with demo — re-applying the bundle
appeared to succeed while changing nothing. Measured against the reference environment:

- **248** localization messages differed (e.g. `CORE_LOADING` = `Loading...` locally vs `Loading` on demo)
- **255** MDMS rows differed, including the 7 console **card-tile** definitions, which is why tiles rendered
  with the wrong labels and in the wrong order

On an **empty** database `DO UPDATE` is identical to `DO NOTHING` (there is nothing to conflict with), so
this is safe for a fresh one-click install. Re-running the bundle is still exactly idempotent — the second
pass rewrites the same values. Verified against a deliberately dirtied database: a stale
`CORE_LOADING = 'Loading...'` and a stale tile `2304 = HCMCONSOLE.CREATE_CAMPAIGN` both converged to demo's
current values on apply.

> **Note the trade-off:** these files now assert demo's values. Any deliberate local customisation of a
> seeded label or master will be overwritten on the next apply. That is intended for this bundle, whose whole
> purpose is to mirror demo — but it is a behaviour change from previous revisions.

### What `DO UPDATE` still cannot fix: surplus rows

An upsert can add and correct rows; it can never **remove** one. A cluster seeded before this bundle existed
keeps its local-only rows through every re-apply, and those render as **duplicate card tiles and duplicate
dropdown options**. Measured against the reference environment (2026-08-20):

| Master | Local-only rows | Visible symptom |
|---|---|---|
| `ACCESSCONTROL-ACTIONS-TEST.actions-test` | 197 (e.g. the id-`5000` series) | `My campaigns` ×3, `Create campaign` ×3, `Boundary management` ×3, `Search user` ×3, `Create user` ×3, `Setup Payment Attributes` ×2 |
| `ACCESSCONTROL-ROLEACTIONS.roleactions` | 497 | grants the surplus actions above |
| `HCM-PROJECT-TYPES.projectTypes` | 1 | **`Co-Delivery` listed twice** in the campaign-type dropdown |
| `HCM-ADMIN-CONSOLE.campaignTypeTemplates` | 1 (`Malaria2024`) | extra template option |

Removing these requires `DELETE`, which is destructive and is **not** part of `apply.sh`. A fresh install is
unaffected — it only ever contains demo's rows.

**`23-align-remove-surplus.sql`** does exactly that removal, for the 5 UI-driving masters only
(`ACCESSCONTROL-ACTIONS-TEST.actions-test`, `ACCESSCONTROL-ROLEACTIONS.roleactions`,
`ACCESSCONTROL-ROLES.roles`, `HCM-PROJECT-TYPES.projectTypes`,
`HCM-ADMIN-CONSOLE.campaignTypeTemplates`). It deletes only rows whose `uniqueidentifier` is absent from
demo's 4,802-row authoritative set, runs in one transaction, and `RAISE NOTICE`s the per-master counts
before deleting. It deliberately does **not** touch campaign-derived masters (`HCM.WORKER_RATES`,
`NewFormConfig`, `NewApkConfig`, …) — on a live cluster those belong to that cluster's own campaigns.

```
psql -v ON_ERROR_STOP=1 -h "$PGHOST" -U "$PGUSER" -d "$PGDATABASE" -f 23-align-remove-surplus.sql
```

Verified on a throwaway PostgreSQL:

| Scenario | Result |
|---|---|
| Fresh DB seeded only from this bundle | **exact no-op** — 0 rows removed, 6,284 → 6,284 |
| DB pre-loaded with 696 real surplus rows, then `21` + `23` | removed 695, converged to **exactly** demo's 6,284 |

After alignment: `Setup Payment Attributes` 2→**1**, `Co-Delivery` 2→**1**, active campaign templates
3→**2** (`Malaria2024` exists on demo but *inactive*, so file `21`'s upsert deactivates it rather than `23`
deleting it). The remaining ×2 tiles are demo's own duplicates, retained by design.

> One clause was deliberately removed from this file after testing: a "delete role-actions whose action no
> longer exists" cleanup. **demo itself carries 143 such dangling role-actions**, so that cleanup deleted 143
> rows from a *freshly seeded* database — diverging from demo and breaking the no-op guarantee. They grant
> nothing and are harmless.

> **Separately: demo itself has duplicate tiles.** 173 of demo's own active action rows are byte-identical
> twins (same `displayName`, `navigationURL`, `parentModule`, `orderNumber`) that are granted to the *same*
> role — e.g. ids `2304`+`2330` are both `HCMCONSOLE.MY_CAMPAIGNS` → `/workbench-ui/employee/campaign/my-campaign-new`,
> both granted to `CAMPAIGN_MANAGER`. So even a perfect mirror of demo shows `My campaigns` and
> `Boundary management` twice. Eliminating those means **diverging from demo**, which this bundle does not do
> on its own authority.

## Apply
```
# A) direct psql
export PGHOST=... PGPORT=5432 PGDATABASE=... PGUSER=... PGPASSWORD=... ; ./apply.sh
# B) pull creds from a running egov-user pod (in-cluster DB)
export KUBECONFIG=/path/to/kubeconfig ; FROM_POD=1 ./apply.sh
```

### Post-apply (BOTH required)
```
# 1. refresh MDMS cache
kubectl rollout restart deploy/mdms-v2 deploy/project-factory -n egov
# 2. bust the localization Redis cache (survives pod restarts; step 1 alone is NOT enough)
kubectl exec -n backbone deploy/redis -- redis-cli DEL messages computedMessages
```
Browsers cache localisation + the boundary tree in IndexedDB — a user seeing raw codes or a truncated
boundary picker needs **Clear-site-data**, not a reload.

## Campaign creation — what `21` enables and one demo-inherited limitation
`21` carries the `HCM-ADMIN-CONSOLE.schemas` rows `target-<projectType>` (e.g. `target-CO-DELIVERY`,
`target-INT-CAMP`, `target-POLIO`). excel-ingestion **requires** the matching `target-<projectType>` row
or campaign processing fails with `Schema 'target-<projectType>' not found in MDMS`. These are ordinary
MDMS **data** rows (not schema defs), so `apply.sh` handles them by running `21`. A unified campaign then
reaches status `created` (UI "Upcoming") end-to-end via API — verified on `mz` for CO-DELIVERY.

**Known limitation (inherited from demo, NOT a seed defect):** the deployed excel-ingestion
(`dynamic-target-columns` build) generates boundary target columns per projectType *product*
(`..._TARGET_CO-DELIVERY_VITAMIN_A_SUPPLEMENT`, `..._AZITHROMYCIN`), but `HCM-ADMIN-CONSOLE.targetConfigs`
still lists legacy column names (CO-DELIVERY → `SPAQ1/SPAQ2/NOPV2/IVERMETCIN/ALBENDAZOLE`; MR-DN → `SMC_*`).
project-factory extracts targets by those stale names → no match → **0 projects** are created for new
campaigns (mappings then fail non-blockingly; the campaign still reaches `created`). This mismatch is
present in hcm-demo itself (confirmed live), so the seed reproduces demo faithfully. To make new campaigns
create projects, update `targetConfigs` per projectType to the dynamic per-product column names — an
upstream/demo data decision, deliberately **not** baked into this demo-mirroring seed.

## Not included (by design — runtime, not seed)
- **20k HANDOVER boundary hierarchy + data** — bulk runtime load via boundary/excel-ingestion.
- **The 2.0-era Postman collections** — GitBook attachments on the docs site.

## Provenance

Refreshed **2026-08-20 ~13:00 IST** directly from the hcm-demo reference environment, tenant `demo`:

| Data | Endpoint | Completeness |
|---|---|---|
| `eg_mdms_data` (`21`) | `POST https://hcm-demo.digit.org/mdms-v2/v2/_search` per schemaCode, paginated over the union of 372 schema codes | **Complete.** `v2/_search` returns `isActive=false` rows when `isActive` is omitted (verified) — unlike `v1`, which is active-only. 6,581 rows pulled, 0 errors. |
| `eg_mdms_schema_definition` (`19`) | `POST /mdms-v2/schema/v1/_search` | 311 defs — **identical** to the committed file; no change. |
| localization (`20`) | `POST /localization/messages/v1/_search?tenantId=demo&locale=<L>` (no module filter ⇒ all modules) | 4,895,783 rows across `en_DEMO`/`pt_DEMO`/`fr_DEMO`, of which 191,106 are seed-worthy per the table above. |
| `product` / `product_variant` (`22`) | — | **Not refreshed**: demo's product API returns 401 and the `HCMADMIN` credentials are the target cluster-only. Still the 2026-08-20 01:14 pgAdmin CSV snapshot. |

### Drift found against the previous (CSV-based) snapshot
- **MDMS:** 8 new rows (all per-campaign airflow config, now excluded) and **7 changed rows**, all
  `ACCESSCONTROL-ACTIONS-TEST.actions-test` console **card-tile** definitions — demo re-shuffled its tiles on
  2026-08-20 (`CREATE_CAMPAIGN`/`MY_CAMPAIGNS` swapped between ids 2304/2305/2331, `BOUNDARY_MANAGEMENT`
  re-namespaced `HCMCONSOLE.*` → `HCMBOUNDARY.*`, id 2329 deactivated). 0 rows deleted.
- **Localization:** **zero** content drift in the 25 previously-seeded modules.

> Demo was being actively edited during this pull. The tile definitions above are a point-in-time snapshot of
> a master someone was mid-way through changing; re-pull before relying on them for a release.

## Validation

Applied against a throwaway PostgreSQL 16 built from the **real upstream DDL** — egov-localization
`V20170502122717` + the 3 later migrations (so `message.message` really is `varchar(500)`), and mdms-v2
`V20230531144020`. Both files apply clean and are exactly idempotent on a second pass
(191,106 / 6,284 rows unchanged). Verified afterwards: tenant is `mz` only, locales are `en_MZ`/`pt_MZ`/`fr_MZ`
only, zero `"demo"` values and zero `*_DEMO` locales in MDMS payloads, zero `CMP-*` localization modules,
all 49 `hcm-base-*` modules present, and `INSIDEMONITORING` intact (it contains the substring `DEMO`, so a
blanket uppercase substitution would corrupt it — the rule is deliberately scoped to avoid that).
