-- Master install script used by the DB team before version control.
-- Run in SQL*Plus as the schema owner:  @install_all.sql
SET DEFINE OFF
SET ECHO OFF
SET FEEDBACK ON
WHENEVER SQLERROR EXIT FAILURE ROLLBACK

@01_tables.sql
@02_sequences.sql
@03_reference_data.sql
@04_functions_procedures.sql
@05_packages.sql
@06_views.sql
@07_triggers.sql
@08_grants.sql
@09_hotfix_2024_03_add_email.sql
@10_sample_data.sql

PROMPT ==== Legacy install finished ====
EXIT
