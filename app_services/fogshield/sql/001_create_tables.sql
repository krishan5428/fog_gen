-- FogShield tables: make them match what the fogshield/ PHP code uses.
-- Database: SecuricoApp. Run on the TEST database first.
--
-- On SecuricoApp these tables ALREADY EXIST (created earlier, all empty on
-- 2026-11-25): tbl_panel_fogshield, tbl_fogshield_logs,
-- tbl_fogshield_4gcom_panel_state, tbl_fogshield_zone_map,
-- tbl_fogshield_event_map, tbl_fogshield_users, tbl_fogshield_device_tokens.
-- This script only ALIGNS them (rename/add/widen columns, add keys); it never
-- drops a table or a column and never deletes data. On a database where a
-- table is missing, it is created as an empty copy of the FireNex table.
-- Safe to re-run: every step checks first. If a step errors, fix and re-run the
-- whole script (finished steps are skipped).

-- Each step is its own batch (GO): a column added/renamed in one batch can
-- then be used by the next (one batch would fail to compile).

------------------------------------------------------------------------------
-- tbl_panel_fogshield — panels (same columns as tbl_panel_firenex)
------------------------------------------------------------------------------
IF OBJECT_ID('dbo.tbl_panel_fogshield', 'U') IS NULL
    SELECT TOP 0 * INTO dbo.tbl_panel_fogshield FROM dbo.tbl_panel_firenex;
GO

-- The existing table calls the IMEI column "imei" (varchar 20). The code,
-- the app (PanelData reads "panel_imei") and FireNex use panel_imei.
IF COL_LENGTH('dbo.tbl_panel_fogshield', 'panel_imei') IS NULL
   AND COL_LENGTH('dbo.tbl_panel_fogshield', 'imei') IS NOT NULL
    EXEC sp_rename 'dbo.tbl_panel_fogshield.imei', 'panel_imei', 'COLUMN';
GO
IF COL_LENGTH('dbo.tbl_panel_fogshield', 'panel_imei') IS NULL
    ALTER TABLE dbo.tbl_panel_fogshield ADD panel_imei VARCHAR(50) NULL;
ELSE
    ALTER TABLE dbo.tbl_panel_fogshield ALTER COLUMN panel_imei VARCHAR(50) NULL;
GO

-- Soft delete (DELETED / INACTIVE) and G4 "last app login", as in FireNex.
IF COL_LENGTH('dbo.tbl_panel_fogshield', 'status') IS NULL
    ALTER TABLE dbo.tbl_panel_fogshield ADD status VARCHAR(20) NULL;
IF COL_LENGTH('dbo.tbl_panel_fogshield', 'last_login_at') IS NULL
    ALTER TABLE dbo.tbl_panel_fogshield ADD last_login_at DATETIME NULL;
GO

IF NOT EXISTS (SELECT 1 FROM sys.key_constraints
               WHERE parent_object_id = OBJECT_ID('dbo.tbl_panel_fogshield') AND type = 'PK')
    ALTER TABLE dbo.tbl_panel_fogshield ADD CONSTRAINT PK_tbl_panel_fogshield PRIMARY KEY (pnl_id);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_tbl_panel_fogshield_usr')
    CREATE INDEX IX_tbl_panel_fogshield_usr  ON dbo.tbl_panel_fogshield (usr_id);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_tbl_panel_fogshield_acc')
    CREATE INDEX IX_tbl_panel_fogshield_acc  ON dbo.tbl_panel_fogshield (pnl_acc_no);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_tbl_panel_fogshield_imei')
    CREATE INDEX IX_tbl_panel_fogshield_imei ON dbo.tbl_panel_fogshield (panel_imei);

GO
------------------------------------------------------------------------------
-- tbl_fogshield_logs — event / push log
------------------------------------------------------------------------------
IF OBJECT_ID('dbo.tbl_fogshield_logs', 'U') IS NULL
BEGIN
    SELECT TOP 0 * INTO dbo.tbl_fogshield_logs FROM dbo.tbl_firenex_logs;
    ALTER TABLE dbo.tbl_fogshield_logs ADD CONSTRAINT PK_tbl_fogshield_logs PRIMARY KEY (id);
END;
GO
-- Existing table has panel_id varchar(6); SR1 account numbers come from the
-- panel and can be longer (tbl_panel_fogshield.pnl_acc_no is varchar 20).
IF COL_LENGTH('dbo.tbl_fogshield_logs', 'panel_id') < 20
    ALTER TABLE dbo.tbl_fogshield_logs ALTER COLUMN panel_id VARCHAR(20) NOT NULL;
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_tbl_fogshield_logs_panel')
    CREATE INDEX IX_tbl_fogshield_logs_panel ON dbo.tbl_fogshield_logs (panel_id, c_on);

GO
------------------------------------------------------------------------------
-- tbl_fogshield_4gcom_panel_state — last G4 dashboard state (matches FireNex)
------------------------------------------------------------------------------
IF OBJECT_ID('dbo.tbl_fogshield_4gcom_panel_state', 'U') IS NULL
    SELECT TOP 0 * INTO dbo.tbl_fogshield_4gcom_panel_state FROM dbo.tbl_firenex_4gcom_panel_state;
GO
IF NOT EXISTS (SELECT 1 FROM sys.key_constraints
               WHERE parent_object_id = OBJECT_ID('dbo.tbl_fogshield_4gcom_panel_state') AND type = 'PK')
    ALTER TABLE dbo.tbl_fogshield_4gcom_panel_state
        ADD CONSTRAINT PK_tbl_fogshield_4gcom_panel_state PRIMARY KEY (panel_id);

GO
------------------------------------------------------------------------------
-- tbl_fogshield_zone_map — zone names per panel (FireNex: tbl_firenex_event_map;
-- FogShield's column is "fog" instead of "fire")
------------------------------------------------------------------------------
IF OBJECT_ID('dbo.tbl_fogshield_zone_map', 'U') IS NULL
    CREATE TABLE dbo.tbl_fogshield_zone_map (
        id         INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_tbl_fogshield_zone_map PRIMARY KEY,
        panel_id   VARCHAR(20)  NOT NULL,
        usr_id     INT          NOT NULL,
        zone_1     VARCHAR(100) NULL,
        zone_2     VARCHAR(100) NULL,
        zone_3     VARCHAR(100) NULL,
        zone_4     VARCHAR(100) NULL,
        fog        VARCHAR(100) NULL,
        updated_on DATETIME     NULL
    );
GO
IF COL_LENGTH('dbo.tbl_fogshield_zone_map', 'panel_id') < 20
    ALTER TABLE dbo.tbl_fogshield_zone_map ALTER COLUMN panel_id VARCHAR(20) NOT NULL;
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_tbl_fogshield_zone_map_panel')
    CREATE INDEX IX_tbl_fogshield_zone_map_panel ON dbo.tbl_fogshield_zone_map (panel_id, usr_id);

GO
-- tbl_fogshield_event_map (raw_code → custom_name), tbl_fogshield_users and
-- tbl_fogshield_device_tokens are left as they are: not used in this phase.
GO

-- Check: the columns the PHP needs must all be listed (expect 6 rows).
SELECT t.name AS table_name, c.name AS column_name, ty.name AS type, c.max_length
FROM sys.columns c
JOIN sys.tables t ON t.object_id = c.object_id
JOIN sys.types ty ON ty.user_type_id = c.user_type_id
WHERE (t.name = 'tbl_panel_fogshield'    AND c.name IN ('panel_imei', 'status', 'last_login_at'))
   OR (t.name = 'tbl_fogshield_logs'     AND c.name = 'panel_id')
   OR (t.name = 'tbl_fogshield_zone_map' AND c.name IN ('panel_id', 'fog'))
ORDER BY t.name, c.name;
