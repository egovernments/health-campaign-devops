#!/usr/bin/env bash
# apply.sh — HCM 2.1 seed data (tenant mz), sourced from hcm-demo (tenant demo -> mz).
#
# DB credentials come from the environment at runtime; NEVER stored here.
#   A) direct:   export PGHOST=... PGPORT=5432 PGDATABASE=... PGUSER=... PGPASSWORD=... ; ./apply.sh
#   B) from pod: export KUBECONFIG=/path ; FROM_POD=1 ./apply.sh   (pulls creds from a running egov-user pod)
#
# The authoritative masters are the demo-sourced files 19/20/21/22 (full MDMS, localization, products).
# The older hand-built 01/02/05/09/10/11/12 are SUPERSEDED by these and are NOT applied (kept for history).
# 03/04/06/07/08 cover things NOT in the MDMS/product/localization export (workflow, PGR, project ALTER, SSO).
set -euo pipefail
cd "$(dirname "$0")"

if [ "${FROM_POD:-0}" = "1" ]; then
  NS="${NS:-egov}"
  UP=$(kubectl get pods -n "$NS" -l app=egov-user --no-headers | awk '$3=="Running"{print $1; exit}')
  [ -n "$UP" ] || { echo "no running egov-user pod in ns $NS"; exit 1; }
  URL=$(kubectl exec -n "$NS" "$UP" -c egov-user -- printenv SPRING_DATASOURCE_URL)
  export PGUSER=$(kubectl exec -n "$NS" "$UP" -c egov-user -- printenv SPRING_DATASOURCE_USERNAME)
  export PGPASSWORD=$(kubectl exec -n "$NS" "$UP" -c egov-user -- printenv SPRING_DATASOURCE_PASSWORD)
  hp=${URL#jdbc:postgresql://}; export PGHOST=${hp%%:*}; rest=${hp#*:}
  export PGPORT=${rest%%/*}; db=${rest#*/}; export PGDATABASE=${db%%\?*}
fi
: "${PGHOST:?set PGHOST or FROM_POD=1}"; : "${PGDATABASE:?}"; : "${PGUSER:?}"
echo ">> target ${PGUSER}@${PGHOST}:${PGPORT:-5432}/${PGDATABASE}"

APPLIED=(); SKIPPED=()
# order: schema-defs -> MDMS masters -> products -> workflow -> pgr -> hierarchy repoint -> project ALTER -> localization
for f in 19-demo-mdms-schema-def-mz.sql \
         21-demo-mdms-data-mz.sql \
         22-demo-products-mz.sql \
         03-workflow.sql \
         04-pgr.sql \
         06-hierarchyschema-handover.sql \
         07-project-department-nullable.sql \
         20-demo-localization-mz.sql; do
  if [ ! -f "$f" ]; then echo ">> SKIP  $f (absent in this copy)"; SKIPPED+=("$f"); continue; fi
  echo ">> applying $f"
  psql -v ON_ERROR_STOP=1 -h "$PGHOST" -p "${PGPORT:-5432}" -U "$PGUSER" -d "$PGDATABASE" -f "$f"
  APPLIED+=("$f")
done

echo
echo "=============================== SEED APPLY SUMMARY ==============================="
echo "applied (${#APPLIED[@]}): ${APPLIED[*]:-none}"
if [ "${#SKIPPED[@]}" -gt 0 ]; then
  echo "!! SKIPPED (${#SKIPPED[@]}): ${SKIPPED[*]} — run is INCOMPLETE even though it exits 0."
fi
echo "SUPERSEDED, deliberately NOT applied (demo-sourced 19/20/21 replace them):"
echo "   01-mdms 02-accesscontrol 05-localization 09-project-types 10-localization-ui-labels 11-mdms-adminschema 12-localization-labels-full"
echo "================================================================================="
echo
echo ">> SSO (optional): fill + apply 08-sso-identityproviders.TEMPLATE.sql per environment."
echo ">> EXISTING clusters only (NOT needed for a fresh install): 23-align-remove-surplus.sql"
echo ">>   19/20/21 can add and correct rows but never REMOVE one, so local-only rows seeded before this"
echo ">>   bundle survive every re-apply and render as duplicate card tiles / dropdown options."
echo ">>   23 deletes exactly those (rows absent on demo) for the 5 UI-driving masters. DESTRUCTIVE."
echo ">>     psql -v ON_ERROR_STOP=1 -h \"\$PGHOST\" -p \"\${PGPORT:-5432}\" -U \"\$PGUSER\" -d \"\$PGDATABASE\" -f 23-align-remove-surplus.sql"
echo ">> POST-APPLY (BOTH required for the seeded data to be served):"
echo ">>   1. MDMS cache refresh:"
echo ">>        kubectl rollout restart deploy/mdms-v2 deploy/project-factory -n egov"
echo ">>   2. Localization Redis cache-bust (survives pod restart, so step 1 alone is NOT enough):"
echo ">>        kubectl exec -n backbone deploy/redis -- redis-cli DEL messages computedMessages"
echo ">>      (adjust redis selector to your workload; see POST-APPLY-localization-cache-bust.md)"
echo ">> Browsers cache localisation + boundaries in IndexedDB -> use Clear-site-data, not reload."
echo ">> done."
