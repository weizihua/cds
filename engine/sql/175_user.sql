-- +migrate Up

-- Update foreign keys for deprecated user table
ALTER TABLE user_key DROP CONSTRAINT IF EXISTS "fk_user_key_user";
select create_foreign_key_idx_cascade('FK_USER_KEY_USER', 'user_key', 'user', 'user_id', 'id');

-- Create auth tables
CREATE TABLE IF NOT EXISTS "authentified_user" (
  id VARCHAR(36) PRIMARY KEY,
  created TIMESTAMP WITH TIME ZONE,
  username TEXT NOT NULL,
  fullname TEXT NOT NULL,
  ring VARCHAR(25) NOT NULL,
  sig BYTEA
);
select create_unique_index('authentified_user','IDX_AUTHENTIFIED_USER_USERNAME','username');

CREATE TABLE IF NOT EXISTS "authentified_user_migration" (
  id BIGSERIAL PRIMARY KEY,
  authentified_user_id VARCHAR(36),
  user_id BIGINT,
  sig BYTEA
);

SELECT create_unique_index('authentified_user_migration', 'IDX_AUTHENTIFIED_USER_MIGRATION_LINK', 'authentified_user_id,user_id');
SELECT create_foreign_key_idx_cascade('FK_AUTHENTIFIED_USER_MIGRATION_USER', 'authentified_user_migration', 'user', 'user_id', 'id');
SELECT create_foreign_key_idx_cascade('FK_AUTHENTIFIED_USER_MIGRATION_AUTHENTIFIED_USER', 'authentified_user_migration', 'authentified_user', 'authentified_user_id', 'id');

CREATE TABLE IF NOT EXISTS "user_contact" (
  id BIGSERIAL PRIMARY KEY,
  created TIMESTAMP WITH TIME ZONE,
  user_id VARCHAR(36),
  type TEXT NOT NULL,
  value TEXT NOT NULL,
  primary_contact BOOLEAN NOT NULL DEFAULT FALSE,
  verified BOOLEAN NOT NULL DEFAULT FALSE,
  sig BYTEA
);

SELECT create_unique_index('user_contact', 'IDX_USER_CONTACT_VALUE', 'type,value');
SELECT create_foreign_key_idx_cascade('FK_USER_CONTACT_AUTHENTIFIED', 'user_contact', 'authentified_user', 'user_id', 'id');

DROP TABLE IF EXISTS auth_consumer;

CREATE TABLE "auth_consumer" (
  id VARCHAR(36) PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  description VARCHAR(255) NOT NULL,
  parent_id VARCHAR(36),
  user_id VARCHAR(36),
  type VARCHAR(64),
  data JSONB,
  created TIMESTAMP WITH TIME ZONE DEFAULT LOCALTIMESTAMP,
  group_ids JSONB,
  scopes JSONB,
  sig BYTEA,
  issued_at TIMESTAMP WITH TIME ZONE DEFAULT LOCALTIMESTAMP
);

SELECT create_foreign_key_idx_cascade('FK_AUTH_CONSUMER_USER', 'auth_consumer', 'authentified_user', 'user_id', 'id');
SELECT create_foreign_key_idx_cascade('FK_AUTH_CONSUMER_PARENT', 'auth_consumer', 'auth_consumer', 'parent_id', 'id');

DROP TABLE IF EXISTS auth_session;

CREATE TABLE "auth_session" (
  id VARCHAR(36) PRIMARY KEY,
  consumer_id VARCHAR(36),
  expire_at TIMESTAMP WITH TIME ZONE,
  created TIMESTAMP WITH TIME ZONE DEFAULT LOCALTIMESTAMP,
  group_ids JSONB,
  scopes JSONB,
  sig BYTEA,
  mfa BOOLEAN NOT NULL DEFAULT FALSE
);

SELECT create_foreign_key_idx_cascade('FK_AUTH_SESSION_CONSUMER', 'auth_session', 'auth_consumer', 'consumer_id', 'id');

-- Update services and workers tables
ALTER TABLE services ADD COLUMN IF NOT EXISTS auth_consumer_id VARCHAR(36);
ALTER TABLE services ADD COLUMN IF NOT EXISTS maintainer JSONB;
ALTER TABLE services ADD COLUMN IF NOT EXISTS public_key BYTEA;
ALTER TABLE services ADD COLUMN IF NOT EXISTS sig BYTEA;
ALTER TABLE services ADD COLUMN IF NOT EXISTS encrypted_jwt BYTEA;
ALTER TABLE services ALTER COLUMN hash DROP NOT NULL;
SELECT create_unique_index('services', 'IDX_SERVICES_AUTH_CONSUMER_ID', 'auth_consumer_id');

ALTER TABLE worker RENAME TO old_worker;

CREATE TABLE "worker" (
  id VARCHAR(36) PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  last_beat TIMESTAMP WITH TIME ZONE NOT NULL,
  status VARCHAR(255) NOT NULL,
  model_id BIGINT NOT NULL,
  job_run_id BIGINT,
  hatchery_id BIGINT NOT NULL,
  auth_consumer_id VARCHAR(36) REFERENCES auth_consumer(id),
  version VARCHAR(255) NOT NULL,
  os VARCHAR(255) NOT NULL,
  arch VARCHAR(255) NOT NULL
);

SELECT create_foreign_key('FK_WORKER_MODEL', 'worker', 'worker_model', 'model_id', 'id');
select create_index('worker', 'IDX_WORKER_MODEL', 'model_id,id');
SELECT create_foreign_key('FK_WORKER_WORKFLOW_NODE_RUN_JOB', 'worker', 'workflow_node_run_job', 'job_run_id', 'id');
SELECT create_unique_index('worker', 'IDX_WORKER_JOB_RUN', 'job_run_id');
SELECT create_unique_index('worker', 'IDX_WORKER_NAME', 'name');
SELECT create_foreign_key('FK_WORKER_SERVICES', 'worker', 'services', 'hatchery_id', 'id');
SELECT create_unique_index('worker', 'IDX_WORKER_AUTH_CONSUMER_ID', 'auth_consumer_id');

ALTER TABLE worker alter column model_id DROP NOT NULL;

-- Update groups and dependencies tables
ALTER TABLE project_group DROP CONSTRAINT IF EXISTS "fk_project_group_pipeline";
SELECT create_foreign_key_idx_cascade('FK_PROJECT_GROUP_PIPELINE', 'project_group', 'project', 'project_id', 'id');
ALTER TABLE group_user DROP CONSTRAINT IF EXISTS "fk_group_user_group";
SELECT create_foreign_key_idx_cascade('FK_GROUP_USER_GROUP', 'group_user', 'group', 'group_id', 'id');
ALTER TABLE group_user DROP CONSTRAINT IF EXISTS "fk_group_user_user";
SELECT create_foreign_key_idx_cascade('FK_GROUP_USER_USER', 'group_user', 'user', 'user_id', 'id');
ALTER TABLE workflow_template DROP CONSTRAINT IF EXISTS "fk_workflow_template_group";
SELECT create_foreign_key('FK_WORKFLOW_TEMPLATE_GROUP', 'workflow_template', 'group', 'group_id', 'id');
ALTER TABLE "action" DROP CONSTRAINT IF EXISTS "fk_action_group";
SELECT create_foreign_key('FK_ACTION_GROUP', 'action', 'group', 'group_id', 'id');

-- TODO DELETE CASCADE access_token when worker is removed

-- +migrate Down
DROP TABLE "authentified_user_migration";
DROP TABLE "user_contact";
DROP TABLE "worker";
DROP TABLE "auth_session";
DROP TABLE "auth_consumer";
DROP TABLE "authentified_user";
ALTER TABLE old_worker RENAME TO worker;