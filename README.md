# FogShield

Flutter app (Android + iOS) for the Securico FogShield product range: add and manage fog generator panels, control them over TCP/IP or SMS, read their logs, and receive push alerts. G4 (4G) devices are controlled over MQTT.

Package name: `fog_gen_new`. Current version: see `version:` in [pubspec.yaml](pubspec.yaml).

## What the app talks to

| Device / service | How | Code |
| --- | --- | --- |
| FogShield Pro / Nexus / Edge (SR1 panels) | TCP to the panel's static IP, then local IP; SMS fallback | [lib/core/responses/socket_repository.dart](lib/core/responses/socket_repository.dart), [lib/core/utils/packets.dart](lib/core/utils/packets.dart) |
| G4 devices (F02L G4, F04L G4, FCOM G4) | MQTT over TLS to AWS IoT, by IMEI | [lib/features/mqtt/](lib/features/mqtt/), flow in [docs/G4_MQTT_FLOW.md](docs/G4_MQTT_FLOW.md) |
| Backend (users, panels, vendors, logs) | HTTPS to FogShield's own folder `app_services/fogshield/` (`WebUrlConstants.baseUrl`), FireNex-style; see [docs/PLAN_FOGSHIELD_BACKEND.md](docs/PLAN_FOGSHIELD_BACKEND.md) | [lib/core/api/](lib/core/api/), [lib/core/data/repo_impl/](lib/core/data/repo_impl/) |
| Push alerts | Firebase Cloud Messaging | [lib/main.dart](lib/main.dart), [lib/app/fogshield_app.dart](lib/app/fogshield_app.dart) |

The panel list is offline-first: it is cached, and adds/updates/deletes made offline are queued and replayed on the next refresh (`PanelCubit`). G4 devices are never saved offline.

## Code layout

```
lib/
  app/            app root, theme, providers
  core/           API client, models (data/pojo), repos, response parsers, SR1 socket, logging, MQTT certificates
  features/mqtt/  G4: MQTT service, commands, parser, screens
  presentation/   cubits, screens, dialogs, bottom sheets, widgets
  utils/          prefs helper (login state, cache), navigation, SMS, responsive sizes
test/             unit, view-model and screen smoke tests (see below)
docs/             flow docs and plans
```

## Setup

Requirements: the Flutter SDK installed on the build machine, Xcode (iOS), Android Studio / SDK (Android). Android builds use Gradle 8.14, AGP 8.11.1 and Kotlin 2.2.20.

```sh
flutter pub get
flutter run            # pick a device
```

`android/app/google-services.json` and `ios/Runner/GoogleService-Info.plist` hold the Firebase config.

## Test

```sh
flutter analyze        # must show 0 errors and 0 warnings
flutter test           # full suite
```

The tests never reach the backend or a real device: HTTP is replaced by a failing adapter, SR1 panels are local `ServerSocket`s on 127.0.0.1, and G4 tests use fakes. Helpers live in [test/helpers/](test/helpers/). Every bug fix ships with a test that fails without the fix.

Screens that need real hardware are checked by hand with [docs/MANUAL_TEST_CHECKLIST.md](docs/MANUAL_TEST_CHECKLIST.md).

## Backend

FogShield's PHP backend lives in [app_services/fogshield/](app_services/fogshield/) (endpoints, SR1/G4 alert handlers, SQL scripts in `sql/`). Only this folder and its tests are in git; the rest of `app_services/` and `common/` (DB and Firebase credentials) are ignored.

```sh
php app_services/fogshield_tests/run_tests.php           # endpoints, no DB needed
php app_services/fogshield_tests/run_handler_tests.php   # alert handlers; needs app_services/firenex/ next to it
```

Deploy: copy the committed `app_services/fogshield/` to the server's `app_services/fogshield/`. Credentials are never in the code: on the server, `fogshield/config.php` holds them (copy [config.example.php](app_services/fogshield/config.example.php) and fill it in). Never commit `config.php`.

## Build and release

```sh
flutter build apk --release        # or: flutter build appbundle
flutter build ipa                  # iOS, needs signing
```

Before a release: bump `version:` in `pubspec.yaml`, add an entry to [CHANGELOG.md](CHANGELOG.md), run analyze + tests, run the manual checklist on Android and iOS, commit, tag.

## How work is done

Every change follows [docs/WORKING_WITH_CLAUDE.md](docs/WORKING_WITH_CLAUDE.md): 5W+H, read-only investigation, a plan, tests, local verification, then live verification. Bigger work has a plan file in `docs/` with phases, gates and sign-offs:

- [docs/PLAN_APP_FLOW_COMPLIANCE.md](docs/PLAN_APP_FLOW_COMPLIANCE.md) — tests, analyzer and safety for the whole app
- [docs/PLAN_G4_IMPORT.md](docs/PLAN_G4_IMPORT.md) — importing the G4 flow from FireNex
