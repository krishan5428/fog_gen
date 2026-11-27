-- FogShield fresh start (decision 2026-11-27: no real FogShield data yet).
-- Empties the FogShield tables, including the 3 demo panels copied by 002
-- and any test users/tokens. Only fogshield tables + fogshield routes are
-- touched; tbl_panel_master, tbl_user and other apps' data stay as they are.
-- After this, 002 is not needed: panels and users are created through the
-- app (fogshield/ endpoints) from scratch.

USE SecuricoApp;
SET XACT_ABORT ON;
BEGIN TRANSACTION;

DELETE FROM dbo.tbl_pnl_map WHERE app_name = 'fogshield';
DELETE FROM dbo.tbl_fogshield_zone_map;
DELETE FROM dbo.tbl_fogshield_event_map;
DELETE FROM dbo.tbl_fogshield_4gcom_panel_state;
DELETE FROM dbo.tbl_fogshield_logs;
DELETE FROM dbo.tbl_panel_fogshield;
DELETE FROM dbo.tbl_fogshield_device_tokens;
DELETE FROM dbo.tbl_fogshield_users;

COMMIT TRANSACTION;

-- Check: every count must be 0.
SELECT 'routes' AS t, COUNT(*) AS n FROM dbo.tbl_pnl_map WHERE app_name = 'fogshield'
UNION ALL SELECT 'panels', COUNT(*) FROM dbo.tbl_panel_fogshield
UNION ALL SELECT 'users',  COUNT(*) FROM dbo.tbl_fogshield_users
UNION ALL SELECT 'tokens', COUNT(*) FROM dbo.tbl_fogshield_device_tokens
UNION ALL SELECT 'logs',   COUNT(*) FROM dbo.tbl_fogshield_logs;
