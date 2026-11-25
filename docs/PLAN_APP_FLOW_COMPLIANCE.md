# Plan — Bring the whole FogShield app onto the WORKING_WITH_CLAUDE flow

Follows [WORKING_WITH_CLAUDE.md](WORKING_WITH_CLAUDE.md). Started 2026-11-25. The G4 import has its own plan: [PLAN_G4_IMPORT.md](PLAN_G4_IMPORT.md).

## 5W + H

| | Answer | Status |
|---|---|---|
| What | Make the whole app meet the flow's ground rules: every module has tests, analyzer clean, a clean committed tree, docs and a changelog, no production risks left in the code | Confirmed ("poora fog_gen app") |
| Why | Today a change can't be proven safe: there is no working test, and the tree mixes work from different sources | — |
| Where | `fog_gen` app only (148 Dart files, ~28k lines). No backend or production change in this plan | — |
| When | **Confirm:** before the next release? | — |
| Who | FogShield users; sign-off by Sunil | **Confirm** |
| How (done) | Full suite passes and covers every cubit, model, parser and view model; `flutter analyze` has 0 errors and 0 warnings; tree clean on `main` and pushed; README + CHANGELOG + manual test checklist exist | — |

## Audit (read-only, 2026-11-25)

Each item is a gap against a rule in WORKING_WITH_CLAUDE.md.

| # | Rule | Evidence | Gap |
|---|---|---|---|
| A1 | Every change ships with tests | Before today `test/` had one file, `widget_test.dart`, and it fails on `main` (`LateInitializationError: AppInfo._cachedVersion`). 71 tests now exist, all for G4/MQTT | No test for login, panels (non-G4), vendors, logs, SR1 control, more settings, packets, socket, models |
| A2 | Clean analysis | `flutter analyze`: 0 errors, 14 warnings, ~180 infos. Warnings: `logs_viewmodel.dart:48-54` dead code / dead `??`, `panel_sr1_fragment.dart:4,651` unused import + element, `splash.dart:11` unused import, `main.dart:74-75` unused vars, `auth_helper.dart:52` unawaited return in try. Infos: 96 `use_build_context_synchronously`, 33 snake_case names, 25 deprecated APIs, 8 `print` | Warnings to fix; infos triaged |
| A3 | Pre-flight: clean tree, commit right after each fix | 65 staged deletions (`linux/ macos/ web/ windows/`), 43 other uncommitted changes, last commit 2026-02-06. Staged `docs/logs.md` is a raw **FireNex** device log (`processName com.securicoelectronics.firenexv2`, real IMEI); `docs/PLAN_4GCOM_OUTPUTS_NOTIFICATIONS.md` is a FireNex plan | Work from different sources mixed; raw logs about to be committed |
| A4 | Secrets stay in secret storage | `utils/auth_helper.dart:124` saves the user's login password in plain `SharedPreferences` (`user_pass`) | Move to `flutter_secure_storage` (already a dependency) or stop storing it |
| A5 | Production never harmed / respect protections | G4 audio uses plain `http://devicecloudlink.com:6001` (from FireNex) | Record; HTTPS needs the server |
| A6 | Standard, repeatable build | Gradle wrapper 8.12 < 8.14 required by the installed Flutter; `flutter build apk` fails without `--android-skip-build-dependency-validation`. No CI | Upgrade wrapper; optional CI |
| A7 | Docs updated, loose ends listed | `README.md` is the Flutter template ("A new Flutter project"); no CHANGELOG | Write both |
| A8 | Verify live | No written manual test steps for any screen | Checklist per screen (Phase 5) |

## Phases

### Phase 0 — Pre-flight (needs Sunil)
Exit gate: tree clean on `main`, every pending change either committed with a clear message or set aside.
- [x] Step 0.1 — Decided (Sunil, 2026-11-25): `linux/ macos/ web/ windows/` deletions were made by Sunil on purpose (app is phone-only) → keep. `docs/logs.md` (raw FireNex device log, real IMEI) and `docs/PLAN_4GCOM_OUTPUTS_NOTIFICATIONS.md` (FireNex plan) → unstaged and deleted here; identical copies remain in the FireNex repo, so nothing is lost. Kept: `4GCOM_MQTT_COMMANDS.md`, `G4_MQTT_FLOW.md`, `WORKING_WITH_CLAUDE.md`, `analysis_options.yaml` (excludes build/platform folders), `android/gradle.properties` + iOS project files + `Podfile.lock` (Flutter migrator / new plugins, needed to build).
- [ ] Step 0.2 — **Waiting for "commit karo".** Commit in separate commits: (a) pending changes that are confirmed, (b) G4 import (PLAN_G4_IMPORT.md), (c) this plan's work, phase by phase.
- Sign-off: ____ / ____ / ____

### Phase 1 — Safety net: tests for everything that has logic
Exit gate: full suite passes; every cubit, model, response parser, packet builder and view model below has tests; each test file was checked to fail when its target logic is broken.
- [x] Step 1.1 — `test/widget_test.dart` fixed: mocks `PackageInfo`, runs `AppInfo.init()` like `main()`, fake video platform (`test/helpers/fake_video_player.dart`, dev dep `video_player_platform_interface`). Also checks the version text.
- [x] Step 1.2 — `test/core/responses_test.dart` (13), `test/core/models_and_packets_test.dart` (13). **Bugs found (tests failed first, pass after fix):**
  - B1 — Parsers threw on a missing/other key (`msg` vs `message`, missing `status`, `data: null`, string ids). A throw is caught upstream as "no network", so e.g. a **server-rejected panel update showed "Updated Offline" and was queued**, and a delete answered with `message` was queued as offline. Fixed in `update_panel_response`, `delete_panel_response`, `panel_response`, `delete_fire/intru_response`, `forgot_pass_response`, `add_complaint_response`, `add_vendor_response`, `get_vendor_response`, `update_no_response`; `VendorData.user_id` and `UserData` (`usr_id`, `status` as string/int).
- [x] Step 1.3 — `test/cubits/user_vendor_cubits_test.dart` (12), `test/cubits/panel_cubit_offline_test.dart` (9): login/signup/forgot/update/delete user, vendors, mappings; panel list cache, offline add/update/delete queued and replayed, server-saved-no-data, server rejection, `resetState`. **Bug found:**
  - B2 — Two list refreshes at once (list screen + the refresh after an offline add) both replayed the offline queue → **the same panel was added to the server twice**. Fixed: `PanelCubit._syncPendingOnce` (a second caller waits for the running sync).
- [x] Step 1.4 — `test/core/auth_helper_test.dart` (3), `test/core/socket_repository_test.dart` (9, local `ServerSocket`s on 127.0.0.1), `test/core/logs_service_test.dart` (3, fake Dio adapter — no real server call). **Bugs found:**
  - B3 — Logout (`clearLoginState`) left the previous user's profile, **plain-text password**, vendor, panel cache, offline queue and logs cache on the device: the next user saw the old panel list and **the old user's unsynced offline actions were sent under the new user's id**. Fixed: logout removes them (FCM token kept); `PanelCubit.resetState()` called at the 3 logout sites (`profile.dart`, `vendor_profile.dart`, `app_drawer.dart`). Trade-off: unsynced offline actions of the user logging out are dropped.
  - B4 — SR1 TCP fallback never worked when the static IP connected but didn't answer: one `Completer` was shared by both targets, so after the static timeout the local IP's reply was ignored. Fixed: one completer per target.
- [x] Step 1.5 — `test/view_models/`: add panel (validation, connect/busy/fail against a local SR1 stand-in, save data), panel list (filter, site/SIM mapping), SR1 dashboard, telephone numbers, Main (connect, busy auto-fix + retry, disconnect sends 013, unreachable), logs. `panel_details_view_model` and `more_settings_view_model` are dialog flows: covered by the smoke tests (Step 1.6) and the manual checklist (Phase 5). **Bugs found:**
  - B6 — SR1 dashboard picked the reply type with `contains("009")`, checked first. An 008 reply with mains code 9 (`…009`) or an 011 time of 10:09 (`100915…`) was parsed as the arm-status reply: **zones/mains not updated and ARMED/DISARMED shown wrong**. Fixed: classify by the reply's packet id.
  - B7 — Telephone numbers: a bad/incomplete 018 reply was ignored silently, the screen showed 10 blank "Disable" slots, and **Save would overwrite all 10 numbers on the panel with DISABLED**. Fixed: fetch-failed toast, and Save is refused until a full read succeeded.
  - B5 — More Settings → Panel ID: when the IP read failed, an SMS fallback sent the literal text `"message"` to the panel and then showed "Address updated successfully." An SMS cannot read a Panel ID (the answer never comes back to the app). **Fixed (Sunil, 2026-11-25: "SMS hata do"):** the fallback is removed; the app explains the Panel ID can only be read over IP — now for every panel type (before, panels that were neither IP nor IP-GSM got no message at all). Test: `test/view_models/more_settings_vm_test.dart` (failed before, passes after).
- [x] Step 1.6 — `test/screens/smoke_test.dart`: 17 screens build on a 360×800 phone with real Montserrat fonts, the app theme and providers (`test/helpers/app_harness.dart`: HTTP disabled, panels on a closed local port — no test can reach the backend or a device); panel type dialog lists the G4 models; panel card shows G4 vs FogShield buttons. Not smoke-tested: the live G4 MQTT screens (dashboard, 4G settings, audio), since they connect to the real AWS broker — covered by FireNex's MQTT tests + manual checklist. **Bug found:**
  - B8 — Telephone numbers: leaving the screen while the read was running notified a disposed view model (debug: red error). Fixed with the same `_isDisposed` guard the SR1/Main view models use.
- Gate check: full suite **193/193 pass** (18 files); every bug test failed before its fix; analyzer 0 errors, only the 14 pre-existing warnings.
- Sign-off: ____ / ____ / ____

### Phase 2 — Analyzer clean
Exit gate: 0 errors, 0 warnings; the full suite still passes; infos either fixed or listed with a reason.
- [x] Step 2.1 — 14 warnings fixed, no behaviour change: dead `?? ""` in `logs_viewmodel.dart`; unused vars in `main.dart`; unused import + unused `_CommandButton` in `panel_sr1_fragment.dart`; unused import in `splash.dart`; `auth_helper.setSmsDialogShown` now awaits inside its `try`. Result: **0 errors, 0 warnings**, 174 infos; 193/193 tests pass.
- [x] Step 2.2 — Infos 174 → 109, tests 193/193:
  - Fixed: 16 `print` → `AppLogger.d` (silent in release). **Security:** `user_repository_impl.login` printed the raw login response (user data + token) to the device log in release builds. 34 `withOpacity` → `withValues(alpha:)` (same colour). `bloc` imports → `flutter_bloc`. `WillPopScope` → `PopScope(canPop: false)` in `progress_with_message.dart` and `main_screen.dart` (same back behaviour). `Table.fromTextArray` → `TableHelper.fromTextArray`. Toast `closeButtonShowType` → `closeButton: ToastCloseButton(...)`.
  - `use_build_context_synchronously` 96 → 67: the panel card (`panel_item.dart`, 29) now checks `context.mounted` after every await; `ProgressDialog.dismiss` keeps running (it checks mounted itself, so the spinner never sticks) and a confirmed G4 command still goes out if the card is rebuilt.
  - Left, with reason: 67 `use_build_context_synchronously` in bottom sheets / login / add panel (each needs a per-screen review; listed in loose ends). 33 + 4 naming infos (`ip_address`, `CACHED_PANELS_KEY`, `VendorData.user_id`…) mirror server keys and public APIs; renaming is churn with no behaviour gain. `DropdownButtonFormField.value` → `initialValue` **not** done: `initialValue` doesn't follow later changes, so Cancel on the telephone screen would stop resetting the dropdown. `RadioListTile.groupValue` (panel filter) → `RadioGroup`: deprecation only.
- Sign-off: ____ / ____ / ____

### Phase 3 — Safety and build
Exit gate: no plain-text password on the device; a standard build works without flags.
- [x] Step 3.1 — Password kept (profile needs it for change password / delete account) but moved to `flutter_secure_storage` (Keychain / Android Keystore). `getPass` moves an old plain copy and deletes it; `setPass` deletes any plain copy; logout deletes the secure copy. Tests in `test/core/auth_helper_test.dart` (failed before, pass after). Rollback note: reverting this makes users whose password was migrated re-enter it only for change-password/delete (login itself doesn't read it).
- [x] Step 3.2 — Gradle 8.12 → 8.14 (`gradle-wrapper.properties`), AGP 8.9.1 → 8.11.1 and Kotlin 2.1.0 → 2.2.20 (`settings.gradle.kts`) — the minimums of the installed Flutter, same as FireNex. `flutter build apk --debug` passes **without** the skip flag; `flutter build ios --debug --no-codesign` passes; `Podfile.lock` unchanged. Release build and a Play/TestFlight upload not tried. Rollback: revert those two files.
- [x] Step 3.3 — A5 recorded in loose ends (server-side: needs HTTPS on `devicecloudlink.com:6001`).
- Sign-off: ____ / ____ / ____

### Phase 4 — Docs
Exit gate: a new developer can build, test and release from the README alone.
- [x] Step 4.1 — `README.md` rewritten (was the Flutter template).
- [x] Step 4.2 — `CHANGELOG.md` created: Unreleased (G4, fixes B1–B8, security, build) + history from git.
- Sign-off: ____ / ____ / ____

### Phase 5 — Verify live (hardware, test account)
Exit gate: every screen in the checklist was run on a real device and matched the expected result.
- [x] Step 5.1 — `docs/MANUAL_TEST_CHECKLIST.md` written (8 sections, Android + iOS columns, includes a re-check for each fixed bug).
- [ ] Step 5.2 — Run it on Android and iOS; record results.
- Sign-off: ____ / ____ / ____

## Rollback
App-only changes, each phase in its own commit: revert that commit. Phase 3.1 keeps reading the old key once, so reverting it does not log users out.

## Change log
- 2026-11-25 — Audit done (A1–A8), plan created.
- 2026-11-25 — Phase 1 Steps 1.1–1.4 done: 134 tests pass; bugs B1–B4 found by tests and fixed (each test failed before its fix).
- 2026-11-25 — Phase 1 done: 193 tests; B6–B8 fixed; B5 open.
- 2026-11-25 — Step 2.1 done: 0 warnings.
- 2026-11-25 — B5 fixed (SMS fallback removed); Step 0.1 decided; FireNex-only docs removed from this repo.
- 2026-11-25 — Phase 3 (3.1–3.3), Phase 4 and Step 5.1 done; 195 tests pass; Android + iOS debug builds pass without flags.
- 2026-11-25 — Step 2.2 done: infos 174 → 109; release login log leak removed. Phase 2 gate met (0 errors, 0 warnings; infos fixed or listed).

## Loose ends
- With no internet **and** no cache, the panel list shows an empty list instead of "No internet and no data available." (`_emitCachedData` always returns true). UX only; not changed.
- Panel delete SMS uses passcode `1234` regardless of the panel's own code (`panel_details_view_model._buildDeletionMessages`, card SMS for non-G4). Confirm this is intended.
- `more_settings_view_model` checks replies with `contains('001'/'002'/'003')`; low risk (single request), but same pattern as B6.
- 67 `use_build_context_synchronously` left in: `bottom_sheet_dialog/*` (panel_id 8, change_address 7, add_number 7, update_destination_ip_data 6, local_ip_settings 5, change_admin_mobile_number 3, user sheets 1 each), `login.dart` 7, `add_ip_gprs_panel.dart` 7, `add_number_solitare.dart` 5, others 1–2.
- A5: G4 audio uses plain `http://devicecloudlink.com:6001` (server needs HTTPS).
- `user_repository_impl.login`: `e.response?.data?['msg']` throws if the error body is a String.
- `main.dart` and `FogShieldApp` both listen to `FirebaseMessaging.onMessage` (two listeners for one push).
- `LogEntry` shows "now" as the time when `event_time` can't be parsed.
- `UpdatePanelResponse` reads `data` but the repo checks `panelData` to detect "saved, no data"; confirm which key the server sends.
