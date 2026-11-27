-- Copy existing FogShield panels from the shared tbl_panel_master into
-- tbl_panel_fogshield, keeping pnl_id so the app's cached panel ids and its
-- offline queue stay valid, and add their tbl_pnl_map routes (see below).
-- tbl_panel_master is only READ, never changed.
-- Run on the TEST database first, after 001_create_tables.sql.
-- Safe to re-run: panels already copied (same pnl_id) are skipped.

SET XACT_ABORT ON;
BEGIN TRANSACTION;

SET IDENTITY_INSERT dbo.tbl_panel_fogshield ON;

INSERT INTO dbo.tbl_panel_fogshield (
    pnl_id, usr_id, pnl_acc_no, panel_name, pnl_type, site_name, site_address,
    pnl_mac, pnl_ver, pnl_line_no, pnl_rcvr_no, ip_add, port_no, static_ip,
    static_port, pass, admin_code, usr_1, usr_2, usr_3, usr_4,
    panel_sim_number, admin_mobile_number, mobile_number_sub_id,
    mobile_number1, mobile_number2, mobile_number3, mobile_number4,
    mobile_number5, mobile_number6, mobile_number7, mobile_number8,
    mobile_number9, mobile_number10, is_ip_panel, is_ip_gsm_panel, c_on
)
SELECT
    m.pnl_id, m.usr_id, m.pnl_acc_no, m.panel_name, m.pnl_type, m.site_name, m.site_address,
    m.pnl_mac, m.pnl_ver, m.pnl_line_no, m.pnl_rcvr_no, m.ip_add, m.port_no, m.static_ip,
    m.static_port, m.pass, m.admin_code, m.usr_1, m.usr_2, m.usr_3, m.usr_4,
    m.panel_sim_number, m.admin_mobile_number, m.mobile_number_sub_id,
    m.mobile_number1, m.mobile_number2, m.mobile_number3, m.mobile_number4,
    m.mobile_number5, m.mobile_number6, m.mobile_number7, m.mobile_number8,
    m.mobile_number9, m.mobile_number10, m.is_ip_panel, m.is_ip_gsm_panel, m.c_on
FROM dbo.tbl_panel_master m
WHERE m.app_type = 'FogShield'
  AND NOT EXISTS (SELECT 1 FROM dbo.tbl_panel_fogshield f WHERE f.pnl_id = m.pnl_id);

SET IDENTITY_INSERT dbo.tbl_panel_fogshield OFF;

-- New ids continue after the highest copied id.
DECLARE @max INT = (SELECT ISNULL(MAX(pnl_id), 0) FROM dbo.tbl_panel_fogshield);
DBCC CHECKIDENT ('dbo.tbl_panel_fogshield', RESEED, @max);

-- Route the copied panels' alerts to fogshield/ (as FireNex does for every
-- FireNex panel): one tbl_pnl_map row per account number. From this moment
-- the root sync_panel_log.php sends these panels' events to
-- fogshield/sync_panel_log.php instead of its legacy branch, so the
-- fogshield/ folder MUST already be uploaded before this script runs.
-- usr_id = lowest owner; the handler notifies every live owner of the number.
MERGE INTO dbo.tbl_pnl_map AS t
USING (
    SELECT pnl_acc_no AS panel_id,
           MIN(CAST(usr_id AS VARCHAR(50))) AS usr_id,
           MAX(NULLIF(LTRIM(RTRIM(pnl_mac)), '')) AS pnl_mac
    FROM dbo.tbl_panel_fogshield
    WHERE NULLIF(LTRIM(RTRIM(pnl_acc_no)), '') IS NOT NULL
      AND ISNULL(LOWER(LTRIM(RTRIM(status))), '') NOT IN ('inactive', 'deleted')
    GROUP BY pnl_acc_no
) AS s
ON t.panel_id = s.panel_id AND t.app_name = 'fogshield'
WHEN NOT MATCHED THEN
    INSERT (panel_id, app_name, usr_id, imei, pnl_mac)
    VALUES (s.panel_id, 'fogshield', s.usr_id, NULL, s.pnl_mac);

COMMIT TRANSACTION;

-- Check: panels without an account number get no route (they keep no alerts
-- path, same as before); account numbers owned by more than one user.
SELECT COUNT(*) AS panels_without_acc_no
FROM dbo.tbl_panel_fogshield WHERE NULLIF(LTRIM(RTRIM(pnl_acc_no)), '') IS NULL;
SELECT pnl_acc_no, COUNT(DISTINCT usr_id) AS owners
FROM dbo.tbl_panel_fogshield
WHERE NULLIF(LTRIM(RTRIM(pnl_acc_no)), '') IS NOT NULL
GROUP BY pnl_acc_no HAVING COUNT(DISTINCT usr_id) > 1;
SELECT COUNT(*) AS fogshield_routes FROM dbo.tbl_pnl_map WHERE app_name = 'fogshield';

-- Check: both counts must be equal.
SELECT
    (SELECT COUNT(*) FROM dbo.tbl_panel_master WHERE app_type = 'FogShield') AS in_master,
    (SELECT COUNT(*) FROM dbo.tbl_panel_fogshield)                           AS in_fogshield;
