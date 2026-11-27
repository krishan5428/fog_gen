# `app_services/` root files — who uses them, what stays after FogShield moves

Read-only audit, 2026-11-25. Source: the local copy in `fog_gen/app_services/` and the app code on this machine (FogShield `fog_gen`, FireNex, Connect `securico_connect_x_flutter`, StaySafe `securico_staysafe`, `securico_x`, Utility), including each app's git history. Nothing was changed.

**Limits:** the local copy may differ from the server. Callers outside these apps (the C# TCP listener, the MQTT bridges, web portals) are not visible here, except where the PHP itself says so. Before removing any file, check the IIS access logs (30 days) for hits on it.

## How the apps reach the backend today

| App | Base path | Root files it calls |
|---|---|---|
| Connect | `app_services/connect/` | none |
| FireNex | `app_services/firenex/` | none |
| StaySafe | `app_services/staysafe/` | `login.php`, `db_file.php` (absolute URLs, upgrade/migration from the old app) |
| FogShield | `app_services/` (root) | 12: users, vendors, panels, logs (below) |
| securico_x, Utility | other backends / own folder | none |

All apps use `app_services/mqtt_certificates/` for MQTT certificates.

## 1. Must stay in the root — panel alerts and shared entry points

| File | Why |
|---|---|
| `sync_panel_log.php` | Router for **every SR1/TCP panel event** (called by the C# TCP listener). Sends each event to `firenex/`, `connect/` or `fogshield/` via `tbl_pnl_map`; panels not in the map go to its legacy branch (`tbl_panel_master` + push + AMS forward). |
| `mqtt_4gcom_alert.php` | Router for **every G4/4GCOM MQTT event** (called by the MQTT bridge); same `tbl_pnl_map` routing (`connect`, `firenex`, `fogshield`). |
| `mqtt_defender_alert.php` | Router for Defender MQTT events; also called by the Connect app. |
| `log_helper.php` | Used by the three routers above. |
| `login.php` | StaySafe calls it directly on upgrade (session refresh for old users), and FogShield uses it today. |
| `db_file.php` | StaySafe uploads the old on-device DB here during upgrade. |

Plus folders: `common/` (DB, FCM, JWT, panel-id lock — shared by everything), `mqtt_certificates/`.

**These are what keep alerts flowing from panels.** The routers stay in the root even after every app has its own folder.

## 2. Used only by FogShield today → move to `fogshield/` (FogShield backend plan)

| File | Tables | Status |
|---|---|---|
| `add_update_panel_master.php`, `get_panels_master.php`, `delete_panel_master.php` | `tbl_panel_master` | **Replaced** by `fogshield/add_panel.php`, `get_panels.php`, `update_panel.php`, `delete_panel.php` (built, not deployed) |
| `fetch_logs.php` | `tbl_gbl_logs` joined to **`tbl_panel_master`** | **Needs `fogshield/fetch_logs.php`**: once panels live in `tbl_panel_fogshield`, this join finds nothing and the Logs screen is empty for new panels |
| `login.php`, `register_user.php`, `forgot_pass.php`, `update_user.php`, `del_user.php` | `tbl_user`, `tbl_device_tokens` | Move later (users phase). `login.php` also stays in the root for StaySafe |
| `add_vendor.php`, `get_vendors.php`, `del_vendor.php` | `tbl_vendor` | Move later (vendors phase) |

**Shared tables:** StaySafe's own folder (`staysafe/login.php`, `get_vendors.php`, `get_fire_nos.php`, …) uses the same `tbl_user`, `tbl_device_tokens`, `tbl_vendor`, `tbl_fire_numbers`. Moving the FogShield *files* is safe; moving FogShield *users/vendors to new tables* needs a decision on users who have both apps.

## 3. Not called by any current app code

Still possibly used by **old app versions on users' phones** (shown where git history proves it) or unknown callers. Keep until the access logs show no hits; then move to an `_archive/` folder rather than deleting.

| Files | Last known caller |
|---|---|
| `add_fire_no.php`, `get_fire_nos.php`, `update_fire_nos.php`, `del_fire_nos.php`, `add_intru_nos.php`, `get_intru_nos.php`, `update_intru_nos.php`, `del_intru_nos.php` | Old FogShield/FireNex/Connect/StaySafe builds. The current FogShield app only lists them as constants (never calls them); StaySafe uses `staysafe/` copies |
| `add_panel_firenex.php`, `get_panel_firenex.php`, `update_panel_firenex.php`, `delete_panel_firenex.php`, `get_zone_alert_firenex.php`, `update_zone_alert_firenex.php` | Old FireNex builds (now `firenex/`) |
| `add_panel_fog_gen.php`, `get_panel_fog_gen.php`, `update_panel_fog_gen.php`, `delete_panel_fog_gen.php` | Old FogShield builds (now `*_master.php`) |
| `add_panel_gbl.php`, `delete_panel_gbl_complete.php` | Old StaySafe builds |
| `add_panel_complete.php`, `get_gbl_panels.php`, `update_panel_gbl.php`, `delete_panel_gbl.php`, `get_user.php`, `logout.php` | Same names exist in `staysafe/` (current StaySafe calls those) |
| `add_update_panel.php` | Old Connect builds |
| `get_panels.php`, `update_panel.php`, `delete_panel.php` | Old builds; current FireNex/Connect call their own folder versions |
| `add_complain.php`, `get_complain_list.php` | Old FogShield builds — see finding F1 |
| `add_log.php`, `add_number_solitare.php`, `update_number_solitare.php`, `app_update.php`, `fogshield_get_products.php`, `pass_update.php`, `update_vendor.php` | No reference found anywhere |
| `migrate_data.php`, `migrate_panel_ids.php`, `view_migrated_data.php`, `diagnose_sqlite.php` | One-off migration/diagnostic tools; no reference. Should not be publicly reachable |

## Findings

- **F1 — Complaints may be broken in FireNex and StaySafe.** Both apps post `add_complain.php` / `get_complain_list.php` relative to their folder (`firenex/…`, `staysafe/…`), but those files exist only in the root of this copy. Check on the server; if missing, either add them to the folders or point the apps at the root.
- **F2 — Legacy SR1 pushes for FogShield likely never arrive.** The root `sync_panel_log.php` legacy branch calls `sendFCMNotification()` without an app name, so `common/fcm.php` uses the Connect Firebase project; the FogShield app's tokens belong to `securicofogshield`. `fogshield/sync_panel_log.php` sends with `'fogshield'`.
- **F3 — Router crash risk.** Root `sync_panel_log.php` `require`s the per-app handler without checking the file exists (`mqtt_4gcom_alert.php` checks). A `tbl_pnl_map` row for an app whose handler file is missing stops the whole dispatch for that panel. Deploy `fogshield/` as a whole; add a `file_exists()` check to the router (separate, signed-off change).
- **F4 — Secrets in code.** AMS Basic-auth credentials and the MQTT bridge secret are hard-coded in PHP; `common/` holds DB credentials and Firebase keys. Move to server config.
- **F5 — Migration/diagnostic scripts** (`migrate_*.php`, `view_migrated_data.php`, `diagnose_sqlite.php`) sit in a public folder.

## What the root looks like once FogShield is fully moved

```
app_services/
  sync_panel_log.php        SR1 router (all apps + legacy)
  mqtt_4gcom_alert.php      4GCOM router
  mqtt_defender_alert.php   Defender router
  log_helper.php            router logging
  login.php, db_file.php    StaySafe upgrade path
  connect/  firenex/  fogshield/  staysafe/  mqtt_certificates/  …other product folders
  _archive/                 group 3, after the access logs show no traffic
```

The legacy branch of `sync_panel_log.php` (and `tbl_panel_master`) can only go once every panel that still reports through it has a `tbl_pnl_map` row: today that is the FogShield SR1 panels added before `fogshield/` is live.
