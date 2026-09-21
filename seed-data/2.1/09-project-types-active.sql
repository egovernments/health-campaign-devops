-- HCM 2.1 seed: mirror demo's active campaign project types on tenant mz.
-- demo (tenant demo) shows 5 active projectTypes: CO-DELIVERY, MR-DN, POLIO, Bednet, Oncho.
-- the target tenant had only 3 (MR-DN, Bednet, Oncho). This activates POLIO (already
-- present, was inactive) and adds CO-DELIVERY (from demo). Idempotent.

-- 1) activate POLIO
UPDATE eg_mdms_data
SET isactive=true, lastmodifiedtime=(extract(epoch from now())*1000)::bigint
WHERE tenantid='mz' AND schemacode='HCM-PROJECT-TYPES.projectTypes'
  AND data->>'code'='POLIO' AND isactive IS DISTINCT FROM true;

-- 2) add CO-DELIVERY (demo definition, already tenantId=mz) if absent
INSERT INTO eg_mdms_data
 (id,tenantid,uniqueidentifier,schemacode,data,isactive,createdby,lastmodifiedby,createdtime,lastmodifiedtime)
SELECT 'd16b84cd-6e99-4d0a-bc62-e76fde95b4f9','mz','CO-DELIVERY','HCM-PROJECT-TYPES.projectTypes',
       '{"id": "8975068f-e0d5-49b9-bb78-e95e05e8232d", "code": "CO-DELIVERY", "name": "Configuration for Multi Round Campaigns", "group": "MALARIA", "cycles": [{"id": 1, "endDate": 1715279400000, "startDate": 1714329000000, "deliveries": [{"id": 1, "doseCriteria": [{"condition": "6<=ageandage<=59", "ProductVariants": [{"name": "Vitamin A Supplement", "quantity": 1, "productVariantId": "PVAR-2026-07-06-000909"}]}, {"condition": "age>=6", "ProductVariants": [{"name": "Azithromycin", "quantity": 1, "productVariantId": "PVAR-2026-07-06-000910"}]}], "deliveryStrategy": "DIRECT", "mandatoryWaitSinceLastDeliveryInDays": null}], "mandatoryWaitSinceLastCycleInDays": null}], "tenantId": "mz", "resources": [{"name": "Vitamin A Supplement", "quantity": 1, "productVariantId": "PVAR-2026-07-06-000909", "isBaseUnitVariant": true}, {"name": "Azithromycin", "quantity": 1, "productVariantId": "PVAR-2026-07-06-000910", "isBaseUnitVariant": true}], "validMaxAge": 1800, "validMinAge": 6, "dashboardUrls": {"DISTRICT_SUPERVISOR": "/health-ui/employee/dss/dashboard/district-health-dashboard-smc", "NATIONAL_SUPERVISOR": "/health-ui/employee/dss/landing/national-health-dashboard-smc", "PROVINCIAL_SUPERVISOR": "/health-ui/employee/dss/dashboard/provincial-health-dashboard-smc"}, "taskProcedure": ["1 bednet is to be distributed per 2 household members.", "If there are 4 household members, 2 bednets should be distributed.", "If there are 5 household members, 3 bednets should be distributed."], "IsCycleDisable": false, "attrAddDisable": false, "beneficiaryType": "INDIVIDUAL", "productCountHide": false, "deliveryAddDisable": true, "eligibilityCriteria": ["All households having members under the age of 18 are eligible.", "Prison inmates are eligible."], "observationStrategy": "DOT1"}'::jsonb,true,'seed-mirror','seed-mirror',
       (extract(epoch from now())*1000)::bigint,(extract(epoch from now())*1000)::bigint
WHERE NOT EXISTS (SELECT 1 FROM eg_mdms_data WHERE tenantid='mz'
   AND schemacode='HCM-PROJECT-TYPES.projectTypes' AND data->>'code'='CO-DELIVERY');

-- verify
SELECT data->>'code' AS code, isactive FROM eg_mdms_data
WHERE tenantid='mz' AND schemacode='HCM-PROJECT-TYPES.projectTypes' AND isactive=true ORDER BY 1;
