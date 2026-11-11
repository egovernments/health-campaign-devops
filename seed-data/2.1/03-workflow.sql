-- 03-workflow.sql (HCM 2.1, tenant mz): businessservice workflow definitions. Idempotent.

-- HCM 2.1 workflow business services (demo->mz) for the target cluster
-- deterministic uuid5 keys; idempotent via WHERE NOT EXISTS
BEGIN;

-- === PAYMENTS.BILLDETAILS (10 states) ===
INSERT INTO eg_wf_businessservice_v2 (businessservice,business,tenantid,uuid,geturi,posturi,createdby,createdtime,lastmodifiedby,lastmodifiedtime,businessservicesla)
SELECT 'PAYMENTS.BILLDETAILS','health-expense','mz','8574441b-5689-5cff-8063-29a36b30cc9c',NULL,NULL,'0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599709018,'0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599709018,0
WHERE NOT EXISTS (SELECT 1 FROM eg_wf_businessservice_v2 WHERE uuid='8574441b-5689-5cff-8063-29a36b30cc9c');
INSERT INTO eg_wf_state_v2 (uuid,tenantid,businessserviceid,state,applicationstatus,sla,docuploadrequired,isstartstate,isterminatestate,createdby,createdtime,lastmodifiedby,lastmodifiedtime,seq,isstateupdatable)
SELECT 'f5ac4d40-2c83-526f-b430-b535623acd5a','mz','8574441b-5689-5cff-8063-29a36b30cc9c',NULL,NULL,NULL,false,true,false,'0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599709018,'0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599709018,0,true
WHERE NOT EXISTS (SELECT 1 FROM eg_wf_state_v2 WHERE uuid='f5ac4d40-2c83-526f-b430-b535623acd5a');
INSERT INTO eg_wf_state_v2 (uuid,tenantid,businessserviceid,state,applicationstatus,sla,docuploadrequired,isstartstate,isterminatestate,createdby,createdtime,lastmodifiedby,lastmodifiedtime,seq,isstateupdatable)
SELECT 'df59db91-6422-5069-80fc-ad1e1b2240e0','mz','8574441b-5689-5cff-8063-29a36b30cc9c','PENDING_VERIFICATION','PENDING_VERIFICATION',NULL,false,false,false,'0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599709018,'0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599709018,1,true
WHERE NOT EXISTS (SELECT 1 FROM eg_wf_state_v2 WHERE uuid='df59db91-6422-5069-80fc-ad1e1b2240e0');
INSERT INTO eg_wf_state_v2 (uuid,tenantid,businessserviceid,state,applicationstatus,sla,docuploadrequired,isstartstate,isterminatestate,createdby,createdtime,lastmodifiedby,lastmodifiedtime,seq,isstateupdatable)
SELECT '8e75a743-5087-576b-b445-b4a1ef052f09','mz','8574441b-5689-5cff-8063-29a36b30cc9c','VERIFICATION_IN_PROGRESS','VERIFICATION_IN_PROGRESS',NULL,false,false,false,'0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599709018,'0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599709018,2,false
WHERE NOT EXISTS (SELECT 1 FROM eg_wf_state_v2 WHERE uuid='8e75a743-5087-576b-b445-b4a1ef052f09');
INSERT INTO eg_wf_state_v2 (uuid,tenantid,businessserviceid,state,applicationstatus,sla,docuploadrequired,isstartstate,isterminatestate,createdby,createdtime,lastmodifiedby,lastmodifiedtime,seq,isstateupdatable)
SELECT '8669364b-d754-5284-9e63-0b58fe2ad118','mz','8574441b-5689-5cff-8063-29a36b30cc9c','VERIFICATION_FAILED','VERIFICATION_FAILED',NULL,false,false,false,'0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599709018,'0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599709018,3,true
WHERE NOT EXISTS (SELECT 1 FROM eg_wf_state_v2 WHERE uuid='8669364b-d754-5284-9e63-0b58fe2ad118');
INSERT INTO eg_wf_state_v2 (uuid,tenantid,businessserviceid,state,applicationstatus,sla,docuploadrequired,isstartstate,isterminatestate,createdby,createdtime,lastmodifiedby,lastmodifiedtime,seq,isstateupdatable)
SELECT '22482907-118f-5f28-b52d-82f29cd9b3a2','mz','8574441b-5689-5cff-8063-29a36b30cc9c','VERIFIED','VERIFIED',NULL,false,false,false,'0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599709018,'0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599709018,4,true
WHERE NOT EXISTS (SELECT 1 FROM eg_wf_state_v2 WHERE uuid='22482907-118f-5f28-b52d-82f29cd9b3a2');
INSERT INTO eg_wf_state_v2 (uuid,tenantid,businessserviceid,state,applicationstatus,sla,docuploadrequired,isstartstate,isterminatestate,createdby,createdtime,lastmodifiedby,lastmodifiedtime,seq,isstateupdatable)
SELECT '1b6e8dd4-b83e-58fc-aacd-66441a9826f8','mz','8574441b-5689-5cff-8063-29a36b30cc9c','UNDER_REVIEW','UNDER_REVIEW',NULL,false,false,false,'0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599709018,'0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599709018,5,true
WHERE NOT EXISTS (SELECT 1 FROM eg_wf_state_v2 WHERE uuid='1b6e8dd4-b83e-58fc-aacd-66441a9826f8');
INSERT INTO eg_wf_state_v2 (uuid,tenantid,businessserviceid,state,applicationstatus,sla,docuploadrequired,isstartstate,isterminatestate,createdby,createdtime,lastmodifiedby,lastmodifiedtime,seq,isstateupdatable)
SELECT '9eb8c685-848a-5b4a-b02f-232b1e3cf56f','mz','8574441b-5689-5cff-8063-29a36b30cc9c','REVIEWED','REVIEWED',NULL,false,false,false,'0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599709018,'0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599709018,6,true
WHERE NOT EXISTS (SELECT 1 FROM eg_wf_state_v2 WHERE uuid='9eb8c685-848a-5b4a-b02f-232b1e3cf56f');
INSERT INTO eg_wf_state_v2 (uuid,tenantid,businessserviceid,state,applicationstatus,sla,docuploadrequired,isstartstate,isterminatestate,createdby,createdtime,lastmodifiedby,lastmodifiedtime,seq,isstateupdatable)
SELECT '06e5f8bf-9340-5964-a66f-65dfb39f8f9f','mz','8574441b-5689-5cff-8063-29a36b30cc9c','PAYMENT_IN_PROGRESS','PAYMENT_IN_PROGRESS',NULL,false,false,false,'0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599709018,'0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599709018,7,false
WHERE NOT EXISTS (SELECT 1 FROM eg_wf_state_v2 WHERE uuid='06e5f8bf-9340-5964-a66f-65dfb39f8f9f');
INSERT INTO eg_wf_state_v2 (uuid,tenantid,businessserviceid,state,applicationstatus,sla,docuploadrequired,isstartstate,isterminatestate,createdby,createdtime,lastmodifiedby,lastmodifiedtime,seq,isstateupdatable)
SELECT 'cfb3c7ee-0193-562a-b37b-ae4176e64706','mz','8574441b-5689-5cff-8063-29a36b30cc9c','PAYMENT_FAILED','PAYMENT_FAILED',NULL,false,false,false,'0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599709018,'0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599709018,8,true
WHERE NOT EXISTS (SELECT 1 FROM eg_wf_state_v2 WHERE uuid='cfb3c7ee-0193-562a-b37b-ae4176e64706');
INSERT INTO eg_wf_state_v2 (uuid,tenantid,businessserviceid,state,applicationstatus,sla,docuploadrequired,isstartstate,isterminatestate,createdby,createdtime,lastmodifiedby,lastmodifiedtime,seq,isstateupdatable)
SELECT 'fbefc4c7-3d49-5e20-aa16-41134ccc0a45','mz','8574441b-5689-5cff-8063-29a36b30cc9c','PAID','PAID',NULL,false,false,true,'0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599709018,'0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599709018,9,false
WHERE NOT EXISTS (SELECT 1 FROM eg_wf_state_v2 WHERE uuid='fbefc4c7-3d49-5e20-aa16-41134ccc0a45');
INSERT INTO eg_wf_action_v2 (uuid,tenantid,currentstate,action,nextstate,roles,createdby,createdtime,lastmodifiedby,lastmodifiedtime,active)
SELECT 'd738bf98-1953-5ce2-9fb2-028c076882b2','mz','f5ac4d40-2c83-526f-b430-b535623acd5a','CREATE','df59db91-6422-5069-80fc-ad1e1b2240e0','PAYMENT_EDITOR,CAMPAIGN_SUPERVISOR','0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599709018,'0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599709018,true
WHERE NOT EXISTS (SELECT 1 FROM eg_wf_action_v2 WHERE uuid='d738bf98-1953-5ce2-9fb2-028c076882b2');
INSERT INTO eg_wf_action_v2 (uuid,tenantid,currentstate,action,nextstate,roles,createdby,createdtime,lastmodifiedby,lastmodifiedtime,active)
SELECT 'd27cef43-e7ca-54db-b055-107c5b2250c9','mz','df59db91-6422-5069-80fc-ad1e1b2240e0','VERIFY','8e75a743-5087-576b-b445-b4a1ef052f09','PAYMENT_EDITOR','0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599709018,'0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599709018,true
WHERE NOT EXISTS (SELECT 1 FROM eg_wf_action_v2 WHERE uuid='d27cef43-e7ca-54db-b055-107c5b2250c9');
INSERT INTO eg_wf_action_v2 (uuid,tenantid,currentstate,action,nextstate,roles,createdby,createdtime,lastmodifiedby,lastmodifiedtime,active)
SELECT '42ffce97-aa38-5722-8a2b-724b05185fca','mz','8e75a743-5087-576b-b445-b4a1ef052f09','VERIFICATION_SUCCESS','22482907-118f-5f28-b52d-82f29cd9b3a2','PAYMENT_EDITOR','0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599709018,'0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599709018,true
WHERE NOT EXISTS (SELECT 1 FROM eg_wf_action_v2 WHERE uuid='42ffce97-aa38-5722-8a2b-724b05185fca');
INSERT INTO eg_wf_action_v2 (uuid,tenantid,currentstate,action,nextstate,roles,createdby,createdtime,lastmodifiedby,lastmodifiedtime,active)
SELECT 'c721a0e0-f505-5f6b-9e98-eb5a5bb3ac62','mz','8e75a743-5087-576b-b445-b4a1ef052f09','FAILED','8669364b-d754-5284-9e63-0b58fe2ad118','PAYMENT_EDITOR','0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599709018,'0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599709018,true
WHERE NOT EXISTS (SELECT 1 FROM eg_wf_action_v2 WHERE uuid='c721a0e0-f505-5f6b-9e98-eb5a5bb3ac62');
INSERT INTO eg_wf_action_v2 (uuid,tenantid,currentstate,action,nextstate,roles,createdby,createdtime,lastmodifiedby,lastmodifiedtime,active)
SELECT '7dab2347-29f2-506d-81c3-d60a1ab75458','mz','8669364b-d754-5284-9e63-0b58fe2ad118','VERIFY','8e75a743-5087-576b-b445-b4a1ef052f09','PAYMENT_EDITOR','0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599709018,'0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599709018,true
WHERE NOT EXISTS (SELECT 1 FROM eg_wf_action_v2 WHERE uuid='7dab2347-29f2-506d-81c3-d60a1ab75458');
INSERT INTO eg_wf_action_v2 (uuid,tenantid,currentstate,action,nextstate,roles,createdby,createdtime,lastmodifiedby,lastmodifiedtime,active)
SELECT 'deaa3cab-db8d-5947-bdc3-e0ba9be8bb49','mz','8669364b-d754-5284-9e63-0b58fe2ad118','IGNORE_ERRORS_AND_VERIFY','22482907-118f-5f28-b52d-82f29cd9b3a2','PAYMENT_EDITOR','0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599709018,'0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599709018,true
WHERE NOT EXISTS (SELECT 1 FROM eg_wf_action_v2 WHERE uuid='deaa3cab-db8d-5947-bdc3-e0ba9be8bb49');
INSERT INTO eg_wf_action_v2 (uuid,tenantid,currentstate,action,nextstate,roles,createdby,createdtime,lastmodifiedby,lastmodifiedtime,active)
SELECT 'f6440227-a8fb-566d-abc1-6940fc4f4944','mz','22482907-118f-5f28-b52d-82f29cd9b3a2','SEND_FOR_REVIEW','1b6e8dd4-b83e-58fc-aacd-66441a9826f8','PAYMENT_EDITOR','0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599709018,'0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599709018,true
WHERE NOT EXISTS (SELECT 1 FROM eg_wf_action_v2 WHERE uuid='f6440227-a8fb-566d-abc1-6940fc4f4944');
INSERT INTO eg_wf_action_v2 (uuid,tenantid,currentstate,action,nextstate,roles,createdby,createdtime,lastmodifiedby,lastmodifiedtime,active)
SELECT 'a4ba988e-1b39-5fce-99f7-e3e39e663d8b','mz','1b6e8dd4-b83e-58fc-aacd-66441a9826f8','SEND_FOR_APPROVAL','9eb8c685-848a-5b4a-b02f-232b1e3cf56f','PAYMENT_REVIEWER','0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599709018,'0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599709018,true
WHERE NOT EXISTS (SELECT 1 FROM eg_wf_action_v2 WHERE uuid='a4ba988e-1b39-5fce-99f7-e3e39e663d8b');
INSERT INTO eg_wf_action_v2 (uuid,tenantid,currentstate,action,nextstate,roles,createdby,createdtime,lastmodifiedby,lastmodifiedtime,active)
SELECT '6fe45852-8797-5d66-a89b-dbc89143f495','mz','9eb8c685-848a-5b4a-b02f-232b1e3cf56f','PAYMENT_INITIATION','06e5f8bf-9340-5964-a66f-65dfb39f8f9f','PAYMENT_APPROVER','0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599709018,'0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599709018,true
WHERE NOT EXISTS (SELECT 1 FROM eg_wf_action_v2 WHERE uuid='6fe45852-8797-5d66-a89b-dbc89143f495');
INSERT INTO eg_wf_action_v2 (uuid,tenantid,currentstate,action,nextstate,roles,createdby,createdtime,lastmodifiedby,lastmodifiedtime,active)
SELECT '83ea6d96-f65b-52c2-841e-ffaa69b1cfc8','mz','06e5f8bf-9340-5964-a66f-65dfb39f8f9f','PAY','fbefc4c7-3d49-5e20-aa16-41134ccc0a45','PAYMENT_APPROVER','0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599709018,'0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599709018,true
WHERE NOT EXISTS (SELECT 1 FROM eg_wf_action_v2 WHERE uuid='83ea6d96-f65b-52c2-841e-ffaa69b1cfc8');
INSERT INTO eg_wf_action_v2 (uuid,tenantid,currentstate,action,nextstate,roles,createdby,createdtime,lastmodifiedby,lastmodifiedtime,active)
SELECT '0311163a-00a9-5632-b0c6-a353f67b76a1','mz','06e5f8bf-9340-5964-a66f-65dfb39f8f9f','FAILED','cfb3c7ee-0193-562a-b37b-ae4176e64706','PAYMENT_APPROVER','0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599709018,'0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599709018,true
WHERE NOT EXISTS (SELECT 1 FROM eg_wf_action_v2 WHERE uuid='0311163a-00a9-5632-b0c6-a353f67b76a1');
INSERT INTO eg_wf_action_v2 (uuid,tenantid,currentstate,action,nextstate,roles,createdby,createdtime,lastmodifiedby,lastmodifiedtime,active)
SELECT '07570d18-98a6-5f5f-ab09-85e27ffc5fb3','mz','cfb3c7ee-0193-562a-b37b-ae4176e64706','PAYMENT_INITIATION','06e5f8bf-9340-5964-a66f-65dfb39f8f9f','PAYMENT_APPROVER','0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599709018,'0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599709018,true
WHERE NOT EXISTS (SELECT 1 FROM eg_wf_action_v2 WHERE uuid='07570d18-98a6-5f5f-ab09-85e27ffc5fb3');

-- === PAYMENTS.BILL (14 states) ===
INSERT INTO eg_wf_businessservice_v2 (businessservice,business,tenantid,uuid,geturi,posturi,createdby,createdtime,lastmodifiedby,lastmodifiedtime,businessservicesla)
SELECT 'PAYMENTS.BILL','health-expense','mz','e89ebc06-bc4c-5205-aeed-84fd5cd5a50d',NULL,NULL,'0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599800969,'0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599800969,0
WHERE NOT EXISTS (SELECT 1 FROM eg_wf_businessservice_v2 WHERE uuid='e89ebc06-bc4c-5205-aeed-84fd5cd5a50d');
INSERT INTO eg_wf_state_v2 (uuid,tenantid,businessserviceid,state,applicationstatus,sla,docuploadrequired,isstartstate,isterminatestate,createdby,createdtime,lastmodifiedby,lastmodifiedtime,seq,isstateupdatable)
SELECT '05c09258-4429-5d0e-bc52-3b85745f31a6','mz','e89ebc06-bc4c-5205-aeed-84fd5cd5a50d',NULL,NULL,NULL,false,true,false,'0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599800969,'0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599800969,0,true
WHERE NOT EXISTS (SELECT 1 FROM eg_wf_state_v2 WHERE uuid='05c09258-4429-5d0e-bc52-3b85745f31a6');
INSERT INTO eg_wf_state_v2 (uuid,tenantid,businessserviceid,state,applicationstatus,sla,docuploadrequired,isstartstate,isterminatestate,createdby,createdtime,lastmodifiedby,lastmodifiedtime,seq,isstateupdatable)
SELECT 'a08ceb32-5d35-57c1-ae9a-b30e99d8fb64','mz','e89ebc06-bc4c-5205-aeed-84fd5cd5a50d','PENDING_VERIFICATION','PENDING_VERIFICATION',NULL,false,false,false,'0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599800969,'0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599800969,1,true
WHERE NOT EXISTS (SELECT 1 FROM eg_wf_state_v2 WHERE uuid='a08ceb32-5d35-57c1-ae9a-b30e99d8fb64');
INSERT INTO eg_wf_state_v2 (uuid,tenantid,businessserviceid,state,applicationstatus,sla,docuploadrequired,isstartstate,isterminatestate,createdby,createdtime,lastmodifiedby,lastmodifiedtime,seq,isstateupdatable)
SELECT '537d5f2c-f1a2-5b72-92d9-37f5f0c54184','mz','e89ebc06-bc4c-5205-aeed-84fd5cd5a50d','VERIFICATION_IN_PROGRESS','VERIFICATION_IN_PROGRESS',NULL,false,false,false,'0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599800969,'0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599800969,2,false
WHERE NOT EXISTS (SELECT 1 FROM eg_wf_state_v2 WHERE uuid='537d5f2c-f1a2-5b72-92d9-37f5f0c54184');
INSERT INTO eg_wf_state_v2 (uuid,tenantid,businessserviceid,state,applicationstatus,sla,docuploadrequired,isstartstate,isterminatestate,createdby,createdtime,lastmodifiedby,lastmodifiedtime,seq,isstateupdatable)
SELECT 'c636d2e2-fc9b-5c6b-8f72-67de4d0096a7','mz','e89ebc06-bc4c-5205-aeed-84fd5cd5a50d','PARTIALLY_VERIFIED','PARTIALLY_VERIFIED',NULL,false,false,false,'0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599800969,'0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599800969,3,true
WHERE NOT EXISTS (SELECT 1 FROM eg_wf_state_v2 WHERE uuid='c636d2e2-fc9b-5c6b-8f72-67de4d0096a7');
INSERT INTO eg_wf_state_v2 (uuid,tenantid,businessserviceid,state,applicationstatus,sla,docuploadrequired,isstartstate,isterminatestate,createdby,createdtime,lastmodifiedby,lastmodifiedtime,seq,isstateupdatable)
SELECT '470ab310-f37e-5f89-9a1c-f0339c40eb55','mz','e89ebc06-bc4c-5205-aeed-84fd5cd5a50d','IGNORING_ERRORS_IN_PROGRESS','IGNORING_ERRORS_IN_PROGRESS',NULL,false,false,false,'0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599800969,'0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599800969,4,false
WHERE NOT EXISTS (SELECT 1 FROM eg_wf_state_v2 WHERE uuid='470ab310-f37e-5f89-9a1c-f0339c40eb55');
INSERT INTO eg_wf_state_v2 (uuid,tenantid,businessserviceid,state,applicationstatus,sla,docuploadrequired,isstartstate,isterminatestate,createdby,createdtime,lastmodifiedby,lastmodifiedtime,seq,isstateupdatable)
SELECT '65db162d-07fa-5db2-8590-555f5b1eec90','mz','e89ebc06-bc4c-5205-aeed-84fd5cd5a50d','FULLY_VERIFIED','FULLY_VERIFIED',NULL,false,false,false,'0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599800969,'0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599800969,5,true
WHERE NOT EXISTS (SELECT 1 FROM eg_wf_state_v2 WHERE uuid='65db162d-07fa-5db2-8590-555f5b1eec90');
INSERT INTO eg_wf_state_v2 (uuid,tenantid,businessserviceid,state,applicationstatus,sla,docuploadrequired,isstartstate,isterminatestate,createdby,createdtime,lastmodifiedby,lastmodifiedtime,seq,isstateupdatable)
SELECT 'd9b4014b-df4f-54d2-8460-e7c990389b6f','mz','e89ebc06-bc4c-5205-aeed-84fd5cd5a50d','SENDING_FOR_REVIEW','SENDING_FOR_REVIEW',NULL,false,false,false,'0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599800969,'0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599800969,6,false
WHERE NOT EXISTS (SELECT 1 FROM eg_wf_state_v2 WHERE uuid='d9b4014b-df4f-54d2-8460-e7c990389b6f');
INSERT INTO eg_wf_state_v2 (uuid,tenantid,businessserviceid,state,applicationstatus,sla,docuploadrequired,isstartstate,isterminatestate,createdby,createdtime,lastmodifiedby,lastmodifiedtime,seq,isstateupdatable)
SELECT '8b0d0eae-d52c-5865-bf7c-3fed84d05bb2','mz','e89ebc06-bc4c-5205-aeed-84fd5cd5a50d','UNDER_REVIEW','UNDER_REVIEW',NULL,false,false,false,'0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599800969,'0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599800969,7,true
WHERE NOT EXISTS (SELECT 1 FROM eg_wf_state_v2 WHERE uuid='8b0d0eae-d52c-5865-bf7c-3fed84d05bb2');
INSERT INTO eg_wf_state_v2 (uuid,tenantid,businessserviceid,state,applicationstatus,sla,docuploadrequired,isstartstate,isterminatestate,createdby,createdtime,lastmodifiedby,lastmodifiedtime,seq,isstateupdatable)
SELECT '8578d40d-a02b-5066-a67a-0f8e81ac1634','mz','e89ebc06-bc4c-5205-aeed-84fd5cd5a50d','REVIEW_IN_PROGRESS','REVIEW_IN_PROGRESS',NULL,false,false,false,'0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599800969,'0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599800969,8,false
WHERE NOT EXISTS (SELECT 1 FROM eg_wf_state_v2 WHERE uuid='8578d40d-a02b-5066-a67a-0f8e81ac1634');
INSERT INTO eg_wf_state_v2 (uuid,tenantid,businessserviceid,state,applicationstatus,sla,docuploadrequired,isstartstate,isterminatestate,createdby,createdtime,lastmodifiedby,lastmodifiedtime,seq,isstateupdatable)
SELECT '34ddacac-8330-55b8-83eb-379cd63d8541','mz','e89ebc06-bc4c-5205-aeed-84fd5cd5a50d','REVIEWED','REVIEWED',NULL,false,false,false,'0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599800969,'0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599800969,9,true
WHERE NOT EXISTS (SELECT 1 FROM eg_wf_state_v2 WHERE uuid='34ddacac-8330-55b8-83eb-379cd63d8541');
INSERT INTO eg_wf_state_v2 (uuid,tenantid,businessserviceid,state,applicationstatus,sla,docuploadrequired,isstartstate,isterminatestate,createdby,createdtime,lastmodifiedby,lastmodifiedtime,seq,isstateupdatable)
SELECT '18ea06c0-663a-5f7f-a511-d252781b54a4','mz','e89ebc06-bc4c-5205-aeed-84fd5cd5a50d','PAYMENT_IN_PROGRESS','PAYMENT_IN_PROGRESS',NULL,false,false,false,'0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599800969,'0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599800969,10,false
WHERE NOT EXISTS (SELECT 1 FROM eg_wf_state_v2 WHERE uuid='18ea06c0-663a-5f7f-a511-d252781b54a4');
INSERT INTO eg_wf_state_v2 (uuid,tenantid,businessserviceid,state,applicationstatus,sla,docuploadrequired,isstartstate,isterminatestate,createdby,createdtime,lastmodifiedby,lastmodifiedtime,seq,isstateupdatable)
SELECT 'b1d214f6-574b-5b24-acca-e467f2c98e37','mz','e89ebc06-bc4c-5205-aeed-84fd5cd5a50d','PAYMENT_FAILED','PAYMENT_FAILED',NULL,false,false,false,'0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599800969,'0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599800969,11,true
WHERE NOT EXISTS (SELECT 1 FROM eg_wf_state_v2 WHERE uuid='b1d214f6-574b-5b24-acca-e467f2c98e37');
INSERT INTO eg_wf_state_v2 (uuid,tenantid,businessserviceid,state,applicationstatus,sla,docuploadrequired,isstartstate,isterminatestate,createdby,createdtime,lastmodifiedby,lastmodifiedtime,seq,isstateupdatable)
SELECT 'cdc0c0b9-7fee-5abc-bcdf-83ee75805189','mz','e89ebc06-bc4c-5205-aeed-84fd5cd5a50d','PARTIALLY_PAID','PARTIALLY_PAID',NULL,false,false,false,'0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599800969,'0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599800969,12,true
WHERE NOT EXISTS (SELECT 1 FROM eg_wf_state_v2 WHERE uuid='cdc0c0b9-7fee-5abc-bcdf-83ee75805189');
INSERT INTO eg_wf_state_v2 (uuid,tenantid,businessserviceid,state,applicationstatus,sla,docuploadrequired,isstartstate,isterminatestate,createdby,createdtime,lastmodifiedby,lastmodifiedtime,seq,isstateupdatable)
SELECT '036b600d-236f-530e-962b-a05c076418e4','mz','e89ebc06-bc4c-5205-aeed-84fd5cd5a50d','FULLY_PAID','FULLY_PAID',NULL,false,false,true,'0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599800969,'0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599800969,13,false
WHERE NOT EXISTS (SELECT 1 FROM eg_wf_state_v2 WHERE uuid='036b600d-236f-530e-962b-a05c076418e4');
INSERT INTO eg_wf_action_v2 (uuid,tenantid,currentstate,action,nextstate,roles,createdby,createdtime,lastmodifiedby,lastmodifiedtime,active)
SELECT '2ecbf9b8-f07d-58e5-9063-599474422364','mz','05c09258-4429-5d0e-bc52-3b85745f31a6','CREATE','a08ceb32-5d35-57c1-ae9a-b30e99d8fb64','PAYMENT_EDITOR,CAMPAIGN_SUPERVISOR','0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599800969,'0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599800969,true
WHERE NOT EXISTS (SELECT 1 FROM eg_wf_action_v2 WHERE uuid='2ecbf9b8-f07d-58e5-9063-599474422364');
INSERT INTO eg_wf_action_v2 (uuid,tenantid,currentstate,action,nextstate,roles,createdby,createdtime,lastmodifiedby,lastmodifiedtime,active)
SELECT '2671ca0c-5137-5672-9c97-e7542cbf0173','mz','a08ceb32-5d35-57c1-ae9a-b30e99d8fb64','VERIFY','537d5f2c-f1a2-5b72-92d9-37f5f0c54184','PAYMENT_EDITOR','0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599800969,'0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599800969,true
WHERE NOT EXISTS (SELECT 1 FROM eg_wf_action_v2 WHERE uuid='2671ca0c-5137-5672-9c97-e7542cbf0173');
INSERT INTO eg_wf_action_v2 (uuid,tenantid,currentstate,action,nextstate,roles,createdby,createdtime,lastmodifiedby,lastmodifiedtime,active)
SELECT '12adbacf-2484-5a7a-a3e4-8ef73ba3c99e','mz','537d5f2c-f1a2-5b72-92d9-37f5f0c54184','FULLY_VERIFY','65db162d-07fa-5db2-8590-555f5b1eec90','PAYMENT_EDITOR','0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599800969,'0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599800969,true
WHERE NOT EXISTS (SELECT 1 FROM eg_wf_action_v2 WHERE uuid='12adbacf-2484-5a7a-a3e4-8ef73ba3c99e');
INSERT INTO eg_wf_action_v2 (uuid,tenantid,currentstate,action,nextstate,roles,createdby,createdtime,lastmodifiedby,lastmodifiedtime,active)
SELECT '4dbd3d7d-2500-5818-bb69-cbf2d0088342','mz','537d5f2c-f1a2-5b72-92d9-37f5f0c54184','PARTIALLY_VERIFY','c636d2e2-fc9b-5c6b-8f72-67de4d0096a7','PAYMENT_EDITOR','0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599800969,'0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599800969,true
WHERE NOT EXISTS (SELECT 1 FROM eg_wf_action_v2 WHERE uuid='4dbd3d7d-2500-5818-bb69-cbf2d0088342');
INSERT INTO eg_wf_action_v2 (uuid,tenantid,currentstate,action,nextstate,roles,createdby,createdtime,lastmodifiedby,lastmodifiedtime,active)
SELECT '87d43ab6-d0d0-5b7b-8442-a79f3404ec3e','mz','537d5f2c-f1a2-5b72-92d9-37f5f0c54184','FAILED','a08ceb32-5d35-57c1-ae9a-b30e99d8fb64','PAYMENT_EDITOR','0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599800969,'0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599800969,true
WHERE NOT EXISTS (SELECT 1 FROM eg_wf_action_v2 WHERE uuid='87d43ab6-d0d0-5b7b-8442-a79f3404ec3e');
INSERT INTO eg_wf_action_v2 (uuid,tenantid,currentstate,action,nextstate,roles,createdby,createdtime,lastmodifiedby,lastmodifiedtime,active)
SELECT 'bde4254a-1b55-5d05-957d-0a1d48699080','mz','c636d2e2-fc9b-5c6b-8f72-67de4d0096a7','VERIFY','537d5f2c-f1a2-5b72-92d9-37f5f0c54184','PAYMENT_EDITOR','0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599800969,'0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599800969,true
WHERE NOT EXISTS (SELECT 1 FROM eg_wf_action_v2 WHERE uuid='bde4254a-1b55-5d05-957d-0a1d48699080');
INSERT INTO eg_wf_action_v2 (uuid,tenantid,currentstate,action,nextstate,roles,createdby,createdtime,lastmodifiedby,lastmodifiedtime,active)
SELECT 'e2df0365-b398-5d4a-8813-02f118e0d0cb','mz','c636d2e2-fc9b-5c6b-8f72-67de4d0096a7','IGNORE_ERRORS_AND_VERIFY','470ab310-f37e-5f89-9a1c-f0339c40eb55','PAYMENT_EDITOR','0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599800969,'0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599800969,true
WHERE NOT EXISTS (SELECT 1 FROM eg_wf_action_v2 WHERE uuid='e2df0365-b398-5d4a-8813-02f118e0d0cb');
INSERT INTO eg_wf_action_v2 (uuid,tenantid,currentstate,action,nextstate,roles,createdby,createdtime,lastmodifiedby,lastmodifiedtime,active)
SELECT '416e727e-65ac-5d95-8c19-3739e9d9bd71','mz','470ab310-f37e-5f89-9a1c-f0339c40eb55','COMPLETE','65db162d-07fa-5db2-8590-555f5b1eec90','PAYMENT_EDITOR','0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599800969,'0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599800969,true
WHERE NOT EXISTS (SELECT 1 FROM eg_wf_action_v2 WHERE uuid='416e727e-65ac-5d95-8c19-3739e9d9bd71');
INSERT INTO eg_wf_action_v2 (uuid,tenantid,currentstate,action,nextstate,roles,createdby,createdtime,lastmodifiedby,lastmodifiedtime,active)
SELECT '619d5cdf-8e2f-5d07-9c36-a431da452733','mz','470ab310-f37e-5f89-9a1c-f0339c40eb55','FAIL','c636d2e2-fc9b-5c6b-8f72-67de4d0096a7','PAYMENT_EDITOR','0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599800969,'0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599800969,true
WHERE NOT EXISTS (SELECT 1 FROM eg_wf_action_v2 WHERE uuid='619d5cdf-8e2f-5d07-9c36-a431da452733');
INSERT INTO eg_wf_action_v2 (uuid,tenantid,currentstate,action,nextstate,roles,createdby,createdtime,lastmodifiedby,lastmodifiedtime,active)
SELECT 'b5fe484a-8550-558a-aa10-3df0a51f8b87','mz','65db162d-07fa-5db2-8590-555f5b1eec90','SEND_FOR_REVIEW','d9b4014b-df4f-54d2-8460-e7c990389b6f','PAYMENT_EDITOR','0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599800969,'0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599800969,true
WHERE NOT EXISTS (SELECT 1 FROM eg_wf_action_v2 WHERE uuid='b5fe484a-8550-558a-aa10-3df0a51f8b87');
INSERT INTO eg_wf_action_v2 (uuid,tenantid,currentstate,action,nextstate,roles,createdby,createdtime,lastmodifiedby,lastmodifiedtime,active)
SELECT 'a3cd4c45-5673-5371-a98d-b80de30a0798','mz','d9b4014b-df4f-54d2-8460-e7c990389b6f','COMPLETE','8b0d0eae-d52c-5865-bf7c-3fed84d05bb2','PAYMENT_EDITOR','0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599800969,'0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599800969,true
WHERE NOT EXISTS (SELECT 1 FROM eg_wf_action_v2 WHERE uuid='a3cd4c45-5673-5371-a98d-b80de30a0798');
INSERT INTO eg_wf_action_v2 (uuid,tenantid,currentstate,action,nextstate,roles,createdby,createdtime,lastmodifiedby,lastmodifiedtime,active)
SELECT '603d2443-e859-5c88-b1db-5701ae0da7ea','mz','d9b4014b-df4f-54d2-8460-e7c990389b6f','FAIL','65db162d-07fa-5db2-8590-555f5b1eec90','PAYMENT_EDITOR','0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599800969,'0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599800969,true
WHERE NOT EXISTS (SELECT 1 FROM eg_wf_action_v2 WHERE uuid='603d2443-e859-5c88-b1db-5701ae0da7ea');
INSERT INTO eg_wf_action_v2 (uuid,tenantid,currentstate,action,nextstate,roles,createdby,createdtime,lastmodifiedby,lastmodifiedtime,active)
SELECT '4ef6fc25-2d9d-51c1-a745-0fdc112674db','mz','8b0d0eae-d52c-5865-bf7c-3fed84d05bb2','SEND_FOR_APPROVAL','8578d40d-a02b-5066-a67a-0f8e81ac1634','PAYMENT_REVIEWER','0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599800969,'0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599800969,true
WHERE NOT EXISTS (SELECT 1 FROM eg_wf_action_v2 WHERE uuid='4ef6fc25-2d9d-51c1-a745-0fdc112674db');
INSERT INTO eg_wf_action_v2 (uuid,tenantid,currentstate,action,nextstate,roles,createdby,createdtime,lastmodifiedby,lastmodifiedtime,active)
SELECT '3d2d1a1f-8bc1-55fa-b2fe-8047f0ef8b83','mz','8578d40d-a02b-5066-a67a-0f8e81ac1634','COMPLETE','34ddacac-8330-55b8-83eb-379cd63d8541','PAYMENT_REVIEWER','0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599800969,'0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599800969,true
WHERE NOT EXISTS (SELECT 1 FROM eg_wf_action_v2 WHERE uuid='3d2d1a1f-8bc1-55fa-b2fe-8047f0ef8b83');
INSERT INTO eg_wf_action_v2 (uuid,tenantid,currentstate,action,nextstate,roles,createdby,createdtime,lastmodifiedby,lastmodifiedtime,active)
SELECT '25faace2-bd62-5840-8509-71b63595b956','mz','8578d40d-a02b-5066-a67a-0f8e81ac1634','FAIL','8b0d0eae-d52c-5865-bf7c-3fed84d05bb2','PAYMENT_REVIEWER','0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599800969,'0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599800969,true
WHERE NOT EXISTS (SELECT 1 FROM eg_wf_action_v2 WHERE uuid='25faace2-bd62-5840-8509-71b63595b956');
INSERT INTO eg_wf_action_v2 (uuid,tenantid,currentstate,action,nextstate,roles,createdby,createdtime,lastmodifiedby,lastmodifiedtime,active)
SELECT 'b8a89ee5-9cc0-54f1-9543-d0631922eea2','mz','34ddacac-8330-55b8-83eb-379cd63d8541','PAYMENT_INITIATION','18ea06c0-663a-5f7f-a511-d252781b54a4','PAYMENT_APPROVER','0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599800969,'0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599800969,true
WHERE NOT EXISTS (SELECT 1 FROM eg_wf_action_v2 WHERE uuid='b8a89ee5-9cc0-54f1-9543-d0631922eea2');
INSERT INTO eg_wf_action_v2 (uuid,tenantid,currentstate,action,nextstate,roles,createdby,createdtime,lastmodifiedby,lastmodifiedtime,active)
SELECT '73f55b65-8738-540d-aade-83ed0caaaac9','mz','18ea06c0-663a-5f7f-a511-d252781b54a4','FULLY_PAY','036b600d-236f-530e-962b-a05c076418e4','PAYMENT_APPROVER','0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599800969,'0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599800969,true
WHERE NOT EXISTS (SELECT 1 FROM eg_wf_action_v2 WHERE uuid='73f55b65-8738-540d-aade-83ed0caaaac9');
INSERT INTO eg_wf_action_v2 (uuid,tenantid,currentstate,action,nextstate,roles,createdby,createdtime,lastmodifiedby,lastmodifiedtime,active)
SELECT '1948769a-a818-534a-b9d3-72768f8e198e','mz','18ea06c0-663a-5f7f-a511-d252781b54a4','PARTIALLY_PAY','cdc0c0b9-7fee-5abc-bcdf-83ee75805189','PAYMENT_APPROVER','0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599800969,'0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599800969,true
WHERE NOT EXISTS (SELECT 1 FROM eg_wf_action_v2 WHERE uuid='1948769a-a818-534a-b9d3-72768f8e198e');
INSERT INTO eg_wf_action_v2 (uuid,tenantid,currentstate,action,nextstate,roles,createdby,createdtime,lastmodifiedby,lastmodifiedtime,active)
SELECT 'fd1f3d79-f7d8-5d19-b4aa-0ba1e25575c9','mz','18ea06c0-663a-5f7f-a511-d252781b54a4','FAILED','b1d214f6-574b-5b24-acca-e467f2c98e37','PAYMENT_APPROVER','0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599800969,'0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599800969,true
WHERE NOT EXISTS (SELECT 1 FROM eg_wf_action_v2 WHERE uuid='fd1f3d79-f7d8-5d19-b4aa-0ba1e25575c9');
INSERT INTO eg_wf_action_v2 (uuid,tenantid,currentstate,action,nextstate,roles,createdby,createdtime,lastmodifiedby,lastmodifiedtime,active)
SELECT '39ae3504-135e-5ef6-8a0d-b56de978746a','mz','b1d214f6-574b-5b24-acca-e467f2c98e37','PAYMENT_INITIATION','18ea06c0-663a-5f7f-a511-d252781b54a4','PAYMENT_APPROVER','0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599800969,'0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599800969,true
WHERE NOT EXISTS (SELECT 1 FROM eg_wf_action_v2 WHERE uuid='39ae3504-135e-5ef6-8a0d-b56de978746a');
INSERT INTO eg_wf_action_v2 (uuid,tenantid,currentstate,action,nextstate,roles,createdby,createdtime,lastmodifiedby,lastmodifiedtime,active)
SELECT '60ce9eaf-5ba5-5a2c-bf74-73ab09a551e4','mz','cdc0c0b9-7fee-5abc-bcdf-83ee75805189','PAYMENT_INITIATION','18ea06c0-663a-5f7f-a511-d252781b54a4','PAYMENT_APPROVER','0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599800969,'0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783599800969,true
WHERE NOT EXISTS (SELECT 1 FROM eg_wf_action_v2 WHERE uuid='60ce9eaf-5ba5-5a2c-bf74-73ab09a551e4');

-- === HCMMUSTERROLL (3 states) ===
INSERT INTO eg_wf_businessservice_v2 (businessservice,business,tenantid,uuid,geturi,posturi,createdby,createdtime,lastmodifiedby,lastmodifiedtime,businessservicesla)
SELECT 'HCMMUSTERROLL','health-muster-roll','mz','22fc2f5c-1242-51b4-98b9-c628abb9157d',NULL,NULL,'0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783753058473,'0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783753058473,0
WHERE NOT EXISTS (SELECT 1 FROM eg_wf_businessservice_v2 WHERE uuid='22fc2f5c-1242-51b4-98b9-c628abb9157d');
INSERT INTO eg_wf_state_v2 (uuid,tenantid,businessserviceid,state,applicationstatus,sla,docuploadrequired,isstartstate,isterminatestate,createdby,createdtime,lastmodifiedby,lastmodifiedtime,seq,isstateupdatable)
SELECT 'b6533a2d-de5c-58f6-81bb-db4f09967deb','mz','22fc2f5c-1242-51b4-98b9-c628abb9157d',NULL,NULL,NULL,false,true,false,'0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783753058473,'0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783753058473,0,true
WHERE NOT EXISTS (SELECT 1 FROM eg_wf_state_v2 WHERE uuid='b6533a2d-de5c-58f6-81bb-db4f09967deb');
INSERT INTO eg_wf_state_v2 (uuid,tenantid,businessserviceid,state,applicationstatus,sla,docuploadrequired,isstartstate,isterminatestate,createdby,createdtime,lastmodifiedby,lastmodifiedtime,seq,isstateupdatable)
SELECT '4ea39794-b353-5902-a0bb-01cffd26e77d','mz','22fc2f5c-1242-51b4-98b9-c628abb9157d','APPROVAL_PENDING','INWORKFLOW',NULL,false,false,false,'0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783753058473,'0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783753058473,1,true
WHERE NOT EXISTS (SELECT 1 FROM eg_wf_state_v2 WHERE uuid='4ea39794-b353-5902-a0bb-01cffd26e77d');
INSERT INTO eg_wf_state_v2 (uuid,tenantid,businessserviceid,state,applicationstatus,sla,docuploadrequired,isstartstate,isterminatestate,createdby,createdtime,lastmodifiedby,lastmodifiedtime,seq,isstateupdatable)
SELECT '1821368f-a99f-5dbb-8f81-3903ca5995f1','mz','22fc2f5c-1242-51b4-98b9-c628abb9157d','APPROVED','ACTIVE',NULL,false,false,true,'0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783753058473,'0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783753058473,2,false
WHERE NOT EXISTS (SELECT 1 FROM eg_wf_state_v2 WHERE uuid='1821368f-a99f-5dbb-8f81-3903ca5995f1');
INSERT INTO eg_wf_action_v2 (uuid,tenantid,currentstate,action,nextstate,roles,createdby,createdtime,lastmodifiedby,lastmodifiedtime,active)
SELECT '7b9cf9cb-219a-5e7c-a3b8-fc109d5c00ba','mz','b6533a2d-de5c-58f6-81bb-db4f09967deb','SUBMIT','4ea39794-b353-5902-a0bb-01cffd26e77d','PROXIMITY_SUPERVISOR','0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783753058473,'0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783753058473,true
WHERE NOT EXISTS (SELECT 1 FROM eg_wf_action_v2 WHERE uuid='7b9cf9cb-219a-5e7c-a3b8-fc109d5c00ba');
INSERT INTO eg_wf_action_v2 (uuid,tenantid,currentstate,action,nextstate,roles,createdby,createdtime,lastmodifiedby,lastmodifiedtime,active)
SELECT 'df313667-78a8-5883-8910-9dd7331d1dfd','mz','4ea39794-b353-5902-a0bb-01cffd26e77d','EDIT','4ea39794-b353-5902-a0bb-01cffd26e77d','PROXIMITY_SUPERVISOR','0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783753058473,'0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783753058473,true
WHERE NOT EXISTS (SELECT 1 FROM eg_wf_action_v2 WHERE uuid='df313667-78a8-5883-8910-9dd7331d1dfd');
INSERT INTO eg_wf_action_v2 (uuid,tenantid,currentstate,action,nextstate,roles,createdby,createdtime,lastmodifiedby,lastmodifiedtime,active)
SELECT 'f70ebd58-1c7e-5b69-a797-3d8b3e8f7f86','mz','4ea39794-b353-5902-a0bb-01cffd26e77d','APPROVE','1821368f-a99f-5dbb-8f81-3903ca5995f1','PROXIMITY_SUPERVISOR','0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783753058473,'0efe1027-d8bd-4e1e-97d4-0039ee5d3b6b',1783753058473,true
WHERE NOT EXISTS (SELECT 1 FROM eg_wf_action_v2 WHERE uuid='f70ebd58-1c7e-5b69-a797-3d8b3e8f7f86');

COMMIT;
