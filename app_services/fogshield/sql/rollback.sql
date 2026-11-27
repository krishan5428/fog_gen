-- Undo 002 (and any use of the fogshield/ endpoints since): remove the data
-- this work put in. Tables are NOT dropped — they existed before this work
-- (created by someone else). Columns added/renamed by 001 stay; they are
-- harmless to anything else.
-- tbl_panel_master is never touched, so the app's old endpoints keep working,
-- and with the fogshield routes gone the root router sends FogShield panel
-- events to its legacy branch again.

SET XACT_ABORT ON;
BEGIN TRANSACTION;

DELETE FROM dbo.tbl_pnl_map WHERE app_name = 'fogshield';
DELETE FROM dbo.tbl_fogshield_zone_map;
DELETE FROM dbo.tbl_fogshield_4gcom_panel_state;
DELETE FROM dbo.tbl_fogshield_logs;
DELETE FROM dbo.tbl_panel_fogshield;

COMMIT TRANSACTION;
