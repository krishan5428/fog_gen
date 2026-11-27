# Plan — FogShield backend folder (`app_services/fogshield/`), built on FireNex

Follows [WORKING_WITH_CLAUDE.md](WORKING_WITH_CLAUDE.md). Started 2026-11-25. Related: [PLAN_G4_IMPORT.md](PLAN_G4_IMPORT.md).

## 5W + H

| | Answer | Status |
|---|---|---|
| What | A `fogshield/` folder in `app_services` with FogShield's own panel + G4 endpoints and tables, built the way `firenex/` works | Confirmed |
| Why | Today FogShield uses shared root files (`*_master.php`, `tbl_panel_master`) that don't save the IMEI, don't create an account number and don't return `pnl_id`, so G4 add can't work; G4 alerts for FogShield have no handler | Evidence below |
| Where | Local copy only: `fog_gen/app_services/fogshield/` + SQL scripts. Deployed by Sunil/backend dev, **test server first** | Confirmed |
| When | Phase 1 = panels + G4 (decided); users/vendors/logs later | Confirmed |
| Who | Owner: Sunil. Backend deploy: Sunil / backend dev | — |
| How (done) | On the test server a G4 device is added from the app (record, account no., `tbl_pnl_map` row), shows in the list with CONNECT, an Evacuate press gives one push, delete cleans up; existing FogShield panels still show | — |

Decisions (Sunil, 2026-11-25): **new tables like FireNex** (not `tbl_panel_master`); **panels + G4 first**; **local only, test server first**.

## Evidence (read-only, local copy of `app_services`)

- FogShield app calls root files: `add_update_panel_master.php`, `get_panels_master.php`, `delete_panel_master.php` → table `tbl_panel_master` (filtered by `app_type`). `add_update_panel_master.php` has no `panel_imei`, does not create `pnl_acc_no`, returns only `status` + `msg`.
- `firenex/` has its own tables: `tbl_panel_firenex` (has `panel_imei`, `status`, `last_login_at`), `tbl_firenex_logs`, `tbl_firenex_4gcom_panel_state`, `tbl_firenex_event_map`, `tbl_firenex_users`, `tbl_firenex_device_tokens`, shares.
- `firenex/add_panel.php`: rejects duplicate live IMEI/MAC, reuses an old account no. for the same hardware, else takes the next 6-digit id from the shared `tbl_pnl_map` (checking `common/panel_id_lock.php`), inserts, seeds `tbl_pnl_map` (`app_name='firenex'`) + event map, returns `panel_id` + `pnl_id`.
- Root router `app_services/mqtt_4gcom_alert.php` already maps `'fogshield' => fogshield/mqtt_4gcom_alert.php` and routes by `tbl_pnl_map.app_name` → **no router change needed**; today FogShield G4 events end in `unrouted_<date>.txt`.
- FogShield users/tokens today: `tbl_user`, `tbl_device_tokens` (root `login.php`).
- FireNex issues **not** copied: `$pnl_acc_no` used before being set in `add_panel.php` (PHP warning); `delete_panel.php` "panel not found" branch deletes **all** of the user's share rows; bridge secret hard-coded.
- **Secrets:** `fog_gen/common/` holds `db.php` and Firebase service-account JSON keys, inside the app repo and not ignored. Added `/app_services/` and `/common/` to `.gitignore` (not committed).

## Phases

### Phase 1 — Tables (SQL, test DB)
Exit gate: tables exist on the test DB with the same column types as FireNex; existing FogShield panels copied with the same `pnl_id`.
- [x] 1.1 `sql/001_create_tables.sql` (now: align existing tables, create only if missing — see change log): `tbl_panel_fogshield`, `tbl_fogshield_logs`, `tbl_fogshield_4gcom_panel_state`, `tbl_fogshield_event_map` created as **empty copies of the FireNex tables** (`SELECT TOP 0 * INTO …`, so column types match exactly), plus primary keys/defaults.
- [x] 1.2 `sql/002_copy_fogshield_panels.sql`: copy `tbl_panel_master WHERE app_type = 'FogShield'` into `tbl_panel_fogshield` keeping `pnl_id` (`IDENTITY_INSERT`), so the app's cached ids and offline queue stay valid. Read-only on the old table.
- [x] 1.3 `sql/rollback.sql`: deletes the `fogshield` rows of `tbl_pnl_map` (no other code writes `app_name='fogshield'`) and the rows in the FogShield tables; never drops tables; old table untouched.
- [x] 1.4 Run by Sunil on **production** `SecuricoApp` (no separate test DB; no backup taken), `fogshield/` uploaded first. 001: all 6 required columns present. 002: 3 panels copied (`in_master 3 = in_fogshield 3`), 0 without account no., 2 routes (`900001` → usr 6, `999999` → usr 14). Account `999999` has 2 owners — likely the SR1 factory-default number; both owners get its alerts (same as legacy). Panels on a default number should be given unique ids.
- Sign-off: ____ / ____ / ____

### Phase 2 — Panel endpoints (`fogshield/`)
Exit gate: `php -l` clean; each endpoint's logic covered by a PHP test with a fake DB; responses match what the FogShield app parses (`panels`, `msg`, `pnl_id`, `panel_acc_no`).
- [x] 2.1 `log_helper.php` (logs under `fogshield/logs/`; `FOGSHIELD_LOG_DIR` override for tests).
- [x] 2.2 `add_panel.php`: FireNex logic; `app_name='fogshield'`; types `FOGGER PANEL` + `4GCOM` (the strings the app sends); 4GCOM requires IMEI; SR1 keeps the account no. read from the panel, G4 gets one from the server (old number → other app's number → next free, skipping locked); `pnl_id` via `OUTPUT INSERTED`; returns `pnl_id`, `panel_acc_no`, `panel_id`.
- [x] 2.3 `get_panels.php`: owner's live panels; response `{status, msg, panels}` (no sharing in phase 1).
- [x] 2.4 `update_panel.php`: FireNex fields minus routing fields (`pnl_type`, `panel_imei`, `pnl_acc_no` can't change); returns the row as `data` and `panelData`.
- [x] 2.5 `delete_panel.php`: soft delete (`DELETED`), clean `tbl_pnl_map` (`fogshield`), event map, logs, 4GCOM state.
- Tests 2.1–2.5: `app_services/fogshield_tests/run_tests.php` (outside the deployable folder) — 39 cases against a fake `sqlsrv` (records every SQL + params): numbering, reuse, locks, duplicates, routing row, response shapes, owner-only update/delete, failure paths. `php -l` clean. Mutation check: routing `app_name` changed → test fails; restored → 39/39.
- [x] 2.6 `sync_panel_log.php` (SR1/TCP alerts for FogShield panels). **Must ship together with `add_panel.php`:** the root `sync_panel_log.php` router `require`s `fogshield/sync_panel_log.php` without checking the file exists, so a `tbl_pnl_map` row with `app_name='fogshield'` and no handler file is a fatal error for that panel's whole dispatch (FireNex/Connect rows of the same panel included). Without a `tbl_pnl_map` row, the legacy fallback looks in `tbl_panel_master` and finds nothing, so new SR1 panels would get no alerts.
- Sign-off: ____ / ____ / ____

### Phase 3 — G4 alerts
Exit gate: router hands FogShield events to `fogshield/mqtt_4gcom_alert.php`; one push per event on the test phone.
- [x] 3.1 `mqtt_4gcom_alert.php`, `event_filter.php`, `4gcom_events.xml` + alert helpers in `log_helper.php`, ported from FireNex with renamed tables, function prefixes (`fsh4g_`, `fogshield_`), class `FogshieldEventFilter`, FCM project `'fogshield'`; tokens from `tbl_device_tokens`, names from `tbl_user`. Hardened vs FireNex: site/IMEI lookups read only the live row (a re-added device shares its number with its deleted row); the (disabled) offline watchdog can't touch deleted panels.
- 2.6 + 3.1 design notes:
  - SR1 handler keeps the **legacy FogShield behaviour** (every event pushed, title "Alert!", body `site / event / status On time`, data `site_name, event_name, event_time` that the app's toast reads) instead of FireNex's fire-code filter, so no current FogShield alert is lost. Adds FireNex's structure: 20 s duplicate guard, global-log dedup by transaction id, `tbl_fogshield_logs` row with SENT/FAILED/NO_TOKENS, removal of tokens FCM rejects.
  - **Finding:** the legacy path sends FogShield SR1 pushes without an app name, so `common/fcm.php` uses the **connect** Firebase project, while the app's tokens belong to `securicofogshield` → those pushes most likely never arrive today. The new handler sends with `'fogshield'`. Confirm on the test server.
  - **AMS forwarding** (legacy only; FireNex/Connect handlers don't forward) is kept in the FogShield handler so moving panels off the legacy path doesn't stop the AMS feed. `FOGSHIELD_AMS_URL` overrides it ("" = off, used by tests).
  - Handlers use only `$fs_`-prefixed locals and unique function/class names: the root routers load several apps' handlers in one request.
- Tests 2.6/3.1: `fogshield_tests/run_handler_tests.php` — 22 cases run router-style in a temp copy of `app_services` (fake DB/FCM, AMS off, no local log writes): push content and project, token dedup and cleanup, 20 s / 12 s dedup, global-log dedup, non-4GCOM and nack/echo skips, and **FireNex + FogShield handlers loaded in the same request** (SR1 and G4). Mutation checks: FireNex function name in the FogShield file → fails; push project `'connect'` → fails; restored → 22/22.
- [ ] 3.2 Live check — **blocked: no panel available to send a test event.** Routes were live 18:52–19:06 on 2026-11-25 (no events in `tbl_fogshield_logs` in that window), then removed (`DELETE FROM tbl_pnl_map WHERE app_name='fogshield'`, 2 rows) so the 3 panels are back on the legacy path until a test panel is available. Copied panel rows and aligned tables kept. To resume: re-run 002 for **one test panel's route only**, send an event, check `tbl_fogshield_logs` + phone; then re-run 002 for all.
- [x] 3.3 Read-only smoke test on production (2026-11-25, by Claude at Sunil's request, no pushes): `get_panels.php usr_id=6` → HTTP 200, `status: true`, panel `pnl_id 116` / `900001` "FOGSHIELD DEMO" with `panel_imei`, `status`, `last_login_at`; `fetch_logs.php usr_id=6 pnl_acc_no=900001` → 20 logs in the app's time format; same with `usr_id=999` → "Panel not found" (owner check works). Panel `900001`'s last event is 2026-02-09, so it would not have produced events during the 18:52–19:06 window anyway.
- Sign-off: ____ / ____ / ____

### Phase 4 — App switch
Exit gate: the app uses `fogshield/` endpoints on the test server; manual checklist sections 2, 8 pass.
- [x] 4.1 `WebUrlConstants.useFogshieldBackend` (default **off**; `--dart-define=FOGSHIELD_BACKEND=true` or flip the default once the server is ready) switches add/get/update/delete panel + logs to `fogshield/…`. Users/vendors stay on root. Contract checked: fields the app posts and keys it reads match the new endpoints (`update_panel.php` ignores `panel_imei`, which the G4 details screen sends but shows read-only — same as FireNex). App suite 198/198 in both modes; analyzer 0/0.
- [x] 4.0 `fogshield/fetch_logs.php`: root `fetch_logs.php` joins `tbl_gbl_logs` to `tbl_panel_master`, so the Logs screen would be empty for panels in `tbl_panel_fogshield` (see APP_SERVICES_ROOT_AUDIT.md). Built: only `usr_id` + `pnl_acc_no` required (the root one demanded IP/MAC/version, so G4 panels always failed), owner + live check (root one had none), SR1 → `tbl_gbl_logs`, G4 → `tbl_fogshield_logs`, same response the app parses. 10 tests; mutation (old table) → fails.
- [ ] 4.2 Manual test on the test server, then production rollout plan (separate sign-off).
- Sign-off: ____ / ____ / ____

### Phase 5 — FogShield users and vendors (FireNex style)
Decisions (Sunil, 2026-11-27): **fresh start** (no real FogShield data; demo rows removed by `sql/003_fresh_start_cleanup.sql`, `002` no longer needed); users and vendors **exactly like FireNex** (`tbl_fogshield_users` with vendor columns, `tbl_fogshield_device_tokens`, plain password as FireNex), **plus** profile edit in `update_user.php` (option B — FireNex's `update_user.php` only stores the FCM token, so FireNex's own profile edits don't save).
- [x] 5.1 `signup.php`, `login.php` (token + JWT), `forgot_password.php` (emails the password; product name FogShield), `update_user.php` (token via `dev_id`/`device_id` + name/email/mobile/password, mobile kept unique), `logout.php` (this phone's token only), `del_user.php` (status STOP, as the root one — FireNex has none), `add_vendor.php` / `get_vendors.php` / `del_vendor.php` (vendor in the user row). Not copied: FireNex roles / factory workers (`tbl_fogshield_users` has no role columns). Token inserts set `c_on` (NOT NULL on the server).
- [x] 5.2 Alert handlers read tokens from `tbl_fogshield_device_tokens` and names from `tbl_fogshield_users`.
- [x] 5.3 App: user and vendor endpoints behind the same switch; vendor calls send `usr_id` + `user_id` and read both the old `vendors` list and the FireNex `vendor` object (`vendor_mob_no`), so the app works with either backend. App suite 200/200 in both modes; analyzer 0/0. Backend tests 72/72 + 24/24; mutation: profile edit removed → fails.
- [ ] 5.4 Deploy: upload the new/changed `fogshield/` files; run `003`; build the app with `--dart-define=FOGSHIELD_BACKEND=true` (or flip the default); sign up → login → add panel → profile edit → vendor → logs on a real phone.
- Sign-off: ____ / ____ / ____

### Later (not in this plan)
Panel sharing (FireNex share/transfer).

## Deploy order (test server)
1. Upload the **whole** `fogshield/` folder at once (incl. `config.php`; check its AMS URL/auth for that server). Do **not** upload `fogshield_tests/`.
2. `sql/001_create_tables.sql`.
3. `sql/002_copy_fogshield_panels.sql` (check the counts it prints). **From this moment existing FogShield SR1 panels' alerts go through `fogshield/sync_panel_log.php`** (it writes their `tbl_pnl_map` rows), so step 1 must be done first.
4. Re-run 002 just before the app switch (Phase 4): panels added through the old endpoints in between get copied and routed (re-runnable; it does not update rows already copied).

## Rollback
Nothing changes for production until Phase 4 is deployed. Phases 1–3 add new tables/files only; `sql/rollback.sql` drops the tables and the `fogshield/` folder can be removed. The old root endpoints and `tbl_panel_master` stay untouched.

## Change log
- 2026-11-25 — Investigation done; plan written; `.gitignore` protects `app_services/` and `common/`.
- 2026-11-25 — Phase 1 SQL written (not run); Phase 2.1–2.5 built and tested (39/39). Next: 2.6 SR1 handler, Phase 3 G4 alerts.
- 2026-11-27 — Switch removed (Sunil: "single flow only"): `WebUrlConstants.baseUrl` is `app_services/fogshield/`, endpoints are plain file names like FireNex; old-backend compatibility in the vendor code removed. Login shows the server's reason on failure. App 200/200.
- 2026-11-27 — Fresh start + users/vendors FireNex style (Phase 5) built and tested; `003_fresh_start_cleanup.sql` added.
- 2026-11-25 — 001 + 002 run on production; routes removed 19:06 pending a live test (see 1.4, 3.2).
- 2026-11-25 — Server check (SecuricoApp, read-only query by Sunil): all `tbl_fogshield_*` tables and `tbl_panel_fogshield` **already exist, all empty**, created earlier by someone else. Differences handled: `tbl_panel_fogshield` has `imei` (not `panel_imei`) and no `status` / `last_login_at` → 001 now **aligns** (rename to `panel_imei`, widen to 50, add the two columns, keys); `tbl_fogshield_logs.panel_id` varchar(6) → widened to 20; `tbl_fogshield_event_map` is a code → custom-name table, so zone names now go to `tbl_fogshield_zone_map` (`fog` column). `tbl_fogshield_users` / `tbl_fogshield_device_tokens` exist (empty) for the users phase. `rollback.sql` no longer drops tables (not ours); it removes only data this work adds. 001 split into GO batches. Tests 50/50 + 24/24.
- 2026-11-25 — 4.0 and 4.1 done (switch off by default). Remaining: deploy on the test server (1.4, 3.2), then 4.2.
- 2026-11-25 — Decisions (Sunil): existing SR1 panels get `tbl_pnl_map` routes like FireNex (002 now seeds them); AMS URL/auth configurable (`fogshield/config.php`); complaints out of scope; FogShield and StaySafe users stay separate accounts (users phase → own table). SR1 handler now pushes to every live owner of the account number (legacy did). Tests 24/24 + 39/39; mutation check for all-owners.
- 2026-11-25 — 2.6 and 3.1 built and tested (22/22). Local build complete; next steps need the test server (1.4, 3.2) and the app switch (Phase 4).

## Loose ends
- FireNex-style choices kept on purpose (Sunil): passwords stored and emailed in plain text; Gmail SMTP password hard-coded in `forgot_password.php` (as FireNex). Revisit together for both apps.
- The app doesn't call `logout.php` on logout (FireNex app doesn't either), so a logged-out phone keeps receiving that user's alerts until the token expires.
- AMS URL/auth: FogShield reads them from `fogshield/config.php`; the root router still hard-codes them.
- G4 "Application Login" push (FireNex behaviour: fires when the app reads the dashboard) is kept; confirm FogShield wants it.
- Root `sync_panel_log.php` should check `file_exists()` before `require` (the MQTT router already does). Production root file: separate change, needs sign-off.
- `app_services/` and `common/` should live outside the app repo.
- Bridge secret `fourg_secret_2026` hard-coded in FireNex (and the root router flow); move to server config.
- Panel types accepted by `fogshield/add_panel.php`: confirm the exact `pnl_type` strings the app sends (`FOGGER PANEL`, `4GCOM`).
