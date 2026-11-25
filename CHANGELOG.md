# Changelog

All notable changes to the FogShield app. Newest first. Dates are commit dates.

## Unreleased

### Added
- G4 (4G) devices over MQTT, imported from FireNex: add device with on-device checks and rollback, panel card quick actions (Evacuate / Alarm Reset / Silence) with SMS fallback, dashboard, settings (Device ID, Destination IP, Telephone, Zone Mappings, Audio), device details. See `docs/G4_MQTT_FLOW.md`, `docs/PLAN_G4_IMPORT.md`.
- Test suite (unit, view-model, screen smoke tests) and a manual test checklist.
- README.

### Fixed
- A panel update or delete rejected by the server was shown as "Updated/Deleted Offline" and queued, because a reply with a missing or differently named key crashed the parser.
- A panel added offline could be sent to the server twice when two list refreshes ran at once.
- Logout left the previous user's profile, password, panel list and offline queue on the phone; the next user saw the old panels and the old user's offline changes were sent under the new account.
- SR1 connection never fell back to the local IP when the static IP connected but did not answer.
- SR1 dashboard showed the wrong ARMED/DISARMED state and stopped updating zones when the mains code was 9 or the panel clock read 10:09.
- Telephone numbers: a failed read showed 10 blank slots and Save then wiped all numbers on the panel; Save is now refused until a full read succeeds.
- Telephone numbers: leaving the screen during the read raised an error.
- More Settings → Panel ID: when the panel was not reachable over IP, the app offered an SMS that sent the text "message" and then said "Address updated successfully". The SMS option is removed; the app now says the Panel ID can only be read over IP.
- The login response (user data and token) was written to the device log in release builds.

### Security
- The login password is now kept in secure storage (Keychain / Android Keystore) instead of plain SharedPreferences; an existing plain copy is moved on first read.

### Changed
- Android build: Gradle 8.14, Android Gradle Plugin 8.11.1, Kotlin 2.2.20 (required by the current Flutter SDK).
- Deprecated Flutter APIs replaced (`withOpacity`, `WillPopScope`, `Table.fromTextArray`, toast close button).

## 1.1.0 — 2026-02-06
- Published version 1.1.0: push notifications on Android and iOS, panel logs, bug fixes.

## Earlier
- 2026-01-13 — Local setup of remote panel data.
- 2026-01-06 — Sounder off and reconnection.
- 2025-12-09 — App integrated with the backend API.
- 2025-10-30 — Last version on the local database.
- 2025-10-18 — IP panel updates.
- 2025-09-24 — Initial version.
