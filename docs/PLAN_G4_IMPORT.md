# Plan — Import the G4 (4GCOM) MQTT flow from FireNex

Follows [WORKING_WITH_CLAUDE.md](WORKING_WITH_CLAUDE.md). Source of truth for the flow: [G4_MQTT_FLOW.md](G4_MQTT_FLOW.md). Started 2026-11-25.

## 5W + H

| | Answer | Status |
|---|---|---|
| What | Bring the FireNex G4 flow into FogShield unchanged: add device with provisioning, dashboard, settings (Device ID, Destination IP, Telephone, Zone Mappings, Audio), device details, quick actions from the panel card | Confirmed ("as it is") |
| Why | FogShield users need to add and control G4 devices from this app | — |
| Where | FogShield app (`fog_gen`), backend `securicoconnect.com/.../app_services/` (`*_master.php` endpoints), AWS IoT broker `a7kwxknv6fhia-ats.iot.eu-north-1.amazonaws.com`, certificate API `mqtt_certificates/get_mqtt_certificates.php` | **Confirm:** same broker and certificate API as FireNex |
| When | Before the next app release | **Confirm:** target date |
| Who | FogShield owners of G4 devices; sign-off by Sunil | **Confirm:** test account and test IMEI |
| How (done) | A G4 device is added on a real panel (Device ID, admin no. and destination read back), the dashboard shows live status, Evacuate / Reset / Silence pulse the right output, and the server keeps the IMEI | — |

Models brought over as-is: `FIRE PANEL-2 ZONE - F02L G4`, `FIRE PANEL-4 ZONE - F04L G4`, `FIRE COMMUNICATOR-MX FCOM G4` (`lib/constants/strings.dart`). **Confirm:** these are the models FogShield sells, or a FogShield G4 model replaces them.

## Evidence so far (read-only)

- FogShield had no IMEI concept: `PanelData` had no `panel_imei`, so nothing could route a panel to MQTT.
- FogShield's backend differs from FireNex's: `add_update_panel_master.php` (FogShield) vs `firenex/add_panel.php`. FogShield's add-panel response is read from `message`, and the app sends `pnl_acc_no` itself (read from the device). FireNex expects the server to return `panel_acc_no` and `pnl_id` for G4.
- **Not yet known:** whether `add_update_panel_master.php` saves `panel_imei` and returns `pnl_id` / `panel_acc_no`, and whether `get_panels_master.php` returns `panel_imei`. Without them, G4 add fails (by design, see Step 1.3) and the card never shows CONNECT.
- The machine's Flutter SDK needs Gradle ≥ 8.14; the project wrapper is 8.12, so a plain `flutter build apk` fails before compiling. Unrelated to this plan.

## Phases

### Phase 0 — Pre-flight
Exit gate: this work sits on a clean, known base and can be committed on its own.
- [ ] Step 0.1 — Sort out changes present before this work started: `analysis_options.yaml`, `pubspec.*`, staged `docs/*`, staged deletion of `linux/ macos/ web/ windows/`, and edits to `android/gradle.properties`, `ios/Podfile.lock`, `ios/Runner.xcodeproj/project.pbxproj`, `ios/Flutter/AppFrameworkInfo.plist`. **Confirm** who made them and whether they ship with this change.
- [ ] Step 0.2 — Backend check (read-only, test account): call `add_update_panel_master.php` once with a test G4 record and record the response keys; confirm `get_panels_master.php` returns `panel_imei`. Delete the test record afterwards.
- Sign-off: ____ / ____ / ____

### Phase 1 — Core import + add device (provisioning)
Exit gate: a G4 device is added on the real panel and its three values read back; a failed check removes the server record.
- [x] Step 1.1 — Packages added: `mqtt_client`, `flutter_secure_storage`, `flutter_screenutil`, `file_picker`, `audioplayers`, `mobile_scanner`, `google_fonts`, `equatable`.
- [x] Step 1.2 — Copied from FireNex unchanged except imports (29 files): `constants/mqtt_constants.dart`, `constants/constants.dart`, `core/repo/mqtt_repository.dart`, `core/mqtt/certificate_store.dart`, `core/logging/app_logger.dart`, `core/utils/toast_helper.dart`, `core/utils/secure_storage_helper.dart`, `features/certificate/**`, `features/mqtt/**`, `presentation/screens/mqtt_panel_details.dart`. `ProgressDialog` replaced with the FireNex version (superset, same API).
- [x] Step 1.3 — Shared code adapted: `PanelData` (+`panelImei`, `shareStatus`, `sharedBy`, `copyWith`), `AddPanelResponse` (reads `pnl_id`, `panel_acc_no`, `msg`/`message`), `PanelRepo.addPanel` (+`imei`, sent as `panel_imei` only when set), `PanelCubit` (+`FourGRepository`, G4 provisioning with rollback). Differences from FireNex: a missing `panel_acc_no` now fails with rollback instead of skipping verification; a G4 panel is never saved offline; rollback finds `pnl_id` by IMEI when the response has none.
- [x] Step 1.4 — Wiring: G4 section in `PanelTypeDialog`, `ScreenUtilInit` around `MaterialApp`, `CertificateStore.initialize()` in `main.dart`, `mqttCertificatesUrl`, `Packets.buildMqttMessage`, camera permission (Android + iOS).
- [x] Step 1.5 — `flutter analyze`: 0 errors, no new warnings. Debug APK builds (with `--android-skip-build-dependency-validation`, see Gradle note).
- [x] Step 1.6 — Tests:
  - `test/features/mqtt/` — FireNex tests copied unchanged except imports (commands/parser, request queue, admin sync): 54/54 pass.
  - `test/g4/add_panel_response_test.dart` — `msg`/`message`, `pnl_id` (string/int), `panel_acc_no`/`pnl_acc_no`, JSON string body, garbage body; `PanelData` IMEI round-trip, defaults, `copyWith`: 8/8 pass.
  - `test/g4/panel_cubit_g4_test.dart` — G4 add with fake server + fake panel: all checks pass (exact command order, `4GCOM`, IMEI, `001234`); handshake fail → nothing saved; server error → not saved offline; no account no. → rollback, no device writes; Device ID mismatch, admin missing, destination null, wrong IP → rollback; non-G4 panel → no MQTT, no IMEI: 9/9 pass.
  - Fails-before check: with the Device ID check disabled, "Device ID read-back mismatch → rollback" fails; restored, all pass. Against committed `main` the G4 tests don't compile (no G4 code there).
  - Full suite: 71 pass, 1 fail (`test/widget_test.dart`, `LateInitializationError: AppInfo._cachedVersion`) — **fails the same way on committed `main`** (checked in a temporary worktree), so pre-existing.
  - `flutter analyze`: 0 errors; no warnings in new/changed files.
  - Test-only hook: `PanelCubit.fourGWriteSettle` (`@visibleForTesting`, 3 s in the app) so tests don't wait 9 s.
- [ ] Step 1.7 — Manual test on the real panel (hardware), test account:
  1. Add Panel → 4G (MQTT) DEVICES → F04L G4. Enter site, IMEI (scan), 4-digit password, admin no., SIM, address → SAVE. Expected log: `$01$000$00` → handshake reply → server save → `$02$013$01$<acc>$000001$000000` → `$01$013$01` read with the same account no. → `$02$008$...` → `$01$008` with the admin no. → `$02$013$02$1$182.73.129.27$05600...` → `$01$013$02`. Toast "Device Added Successfully".
  2. Wrong password → "Device MQTT handshake failed", no server record.
  3. Power the panel off after the server save (or block MQTT) → a "... verification failed. Device removed." toast and the record is gone from the list.
- Sign-off: ____ / ____ / ____

### Phase 2 — Panel card + dashboard
Exit gate: CONNECT opens a live session; Evacuate / Alarm Reset / Silence pulse Outputs 1 / 2 / 3 from both the card and the dashboard.
- [x] Step 2.1 — Card: G4 panels show EVACUATE, ALARM RESET, SILENCE, CONNECT; DETAILS opens `MqttPanelDetailsScreen`. Quick actions: 8 s connect cap, 011 enable check (no 001 read), ON → 9 s → OFF, SMS fallback `< PASS OUTPUT n ON/OFF >`.
- [ ] Step 2.2 — Manual test (hardware):
  1. Card → Evacuate → `$01$011$081`, then `$02$012$081$1`; about 9 s later `$02$012$081$0`; **no** `$01$001`. Repeat Alarm Reset (082) and Silence (083).
  2. Press a second card button while one runs → "A command is already running on this device."
  3. Panel offline → after ~8 s, "Device Unreachable" → SMS offer.
  4. CONNECT → dashboard shows signal, mains, battery, zones; pull to refresh; send each command; put the app in the background > 30 s and resume (RECONNECTING then live); Back → "Device Disconnected".
- Sign-off: ____ / ____ / ____

### Phase 3 — Settings + device details
Exit gate: each settings page reads and writes the real panel; an admin change reaches the panel before the server.
- [ ] Step 3.1 — Manual test (hardware): Device ID shows the account no.; Destination IP read + update; Telephone read + save (admin change updates the server after the ack); Zone Mappings rename + enable for each input; Audio upload + download to the panel; Device Details admin change uses the short-lived link; delete asks twice.
- Sign-off: ____ / ____ / ____

### Phase 4 — Close out
Exit gate: committed and pushed, docs updated, loose ends listed.
- [ ] Step 4.1 — Commit only the files of this plan (not the Phase 0 changes unless confirmed), push.
- [ ] Step 4.2 — Update `G4_MQTT_FLOW.md` with the FogShield-specific differences (Step 1.3).
- Sign-off: ____ / ____ / ____

## Rollback

App only; no backend change in this plan. Revert the commit from Step 4.1. Before that commit: `git checkout -- <changed files>` and delete the new files listed in Step 1.2 plus `lib/constants/strings.dart`, `test/features/mqtt/`, `test/g4/`.

## Change log
- 2026-11-25 — Plan created after the code import (Steps 1.1–1.5 and 2.1 were built before this plan existed, out of the flow's order; their gates are recorded here instead).

- 2026-11-25 — Step 1.6 done: 71/71 G4 + MQTT tests pass; fails-before check done by disabling the Device ID check.

## Loose ends
- `test/widget_test.dart` (Splash) fails on `main` too: `AppInfo` isn't initialised in the test. Pre-existing.
- Gradle wrapper 8.12 < 8.14 needed by the installed Flutter; plain `flutter build apk` fails.
- Dashboard "Logs" tile opens FogShield's logs screen (`fetch_logs.php`), not FireNex's; G4 events may not appear there.
- FogShield has no user roles, so the FireNex factory-worker "Release to market" option never shows.
- FireNex's `test/presentation/screens/mqtt_panel_details_test.dart` was not copied (depends on FireNex mocks and `PanelLocalDataSource`).
- Destination IP `182.73.129.27:05600`, country code `+91` and audio server `http://devicecloudlink.com:6001` stay hard-coded (plain HTTP), as in FireNex.
