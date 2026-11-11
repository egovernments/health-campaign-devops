-- 07-project-department-nullable.sql  (HCM 2.1)
--
-- The project service's `project` table declares `department` NOT NULL, but the
-- HCM 2.1 campaign->project mapping (project-factory) creates projects without a
-- department. The persister then dead-letters every save-project message with a
-- NOT NULL violation, so campaigns never reach status=created.
--
-- This relaxes the constraint so departmentless projects persist. It reproduces
-- the live fix applied on the cluster.
--
-- PROPER HOME: this ideally belongs as a Flyway migration in the project service
-- source repo (health-campaign-services, egov-project db migrations), not as a
-- standalone seed step. It is included here so the handoff bundle is complete;
-- fold it into the service migration when that repo is available.
--
-- Idempotent: DROP NOT NULL is a no-op if the column is already nullable.

ALTER TABLE project ALTER COLUMN department DROP NOT NULL;
