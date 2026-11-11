-- 06-hierarchyschema-handover.sql  (HCM 2.1, tenant mz)
--
-- Campaign template generation (project-factory) looks up the HierarchySchema
-- row whose data.hierarchy == the campaign's hierarchyType. For HCM 2.1 the
-- campaign hierarchy is HANDOVER (COUNTRY..VILLAGE), but the base MDMS seed
-- ships the 'campaign' HierarchySchema row pointing at hierarchy 'ADMIN', so the
-- lookup returns 0 rows and project-factory fails with "Mdms Data not present".
--
-- The schema pins data.type to enum [default,microplan,campaign,console] and
-- marks it x-unique, so a NEW 5th row cannot be added -- the existing 'campaign'
-- row must be REPOINTED. This repoints ONLY that row (console/boundary/microplan
-- stay on ADMIN so admin screens keep working).
--
-- Idempotent. Requires an mdms-v2 cache refresh afterwards
-- (kubectl rollout restart deploy/mdms-v2 deploy/project-factory -n egov).

UPDATE eg_mdms_data
SET data = jsonb_set(jsonb_set(jsonb_set(
             data,
             '{hierarchy}',        '"HANDOVER"', true),
             '{lowestHierarchy}',  '"VILLAGE"',  true),
             '{highestHierarchy}', '"COUNTRY"',  true),
    lastmodifiedtime = (extract(epoch from now())*1000)::bigint
WHERE schemacode      = 'HCM-ADMIN-CONSOLE.HierarchySchema'
  AND uniqueidentifier = 'campaign'
  AND tenantid        = 'mz'
  AND (data->>'hierarchy') IS DISTINCT FROM 'HANDOVER';

-- Verify: expect one row, hierarchy=HANDOVER, lowestHierarchy=VILLAGE
--   SELECT uniqueidentifier, data->>'hierarchy', data->>'lowestHierarchy'
--   FROM eg_mdms_data
--   WHERE schemacode='HCM-ADMIN-CONSOLE.HierarchySchema' AND tenantid='mz';
