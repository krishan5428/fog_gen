# Firenex – G4 (4G) Model Flow

As of 2026-11-25. Written for developers moving the G4 flow into another app.

## Overview

The G4 models connect to the app over MQTT on AWS IoT Core, not over TCP or SMS. Each panel is identified by its 15-digit IMEI, and the app talks to it with `ST*`…`*ED` text frames. On the server these panels are saved with `pnl_type = 4GCOM`.

G4 models covered (from `lib/constants/strings.dart`):

| Model name | Zones |
| --- | --- |
| FIRE PANEL-2 ZONE - F02L G4 | 2 |
| FIRE PANEL-4 ZONE - F04L G4 | 4 |
| FIRE COMMUNICATOR-MX FCOM G4 | 4 (communicator; mains bit is inverted) |

The app finds a G4 panel by `panelData.panelImei` being non-empty. That check sends the panel to the MQTT screens instead of the TCP/SMS ones.

Connection constants (`lib/constants/mqtt_constants.dart`):

| Item | Value |
| --- | --- |
| Broker | `a7kwxknv6fhia-ats.iot.eu-north-1.amazonaws.com` |
| Port | 8883 (TLS, mutual auth) |
| Keep-alive | 20 s, `disconnectOnNoResponsePeriod = 10` |
| App publishes to | `QlMQTT/{IMEI}/b` |
| App subscribes to | `QlMQTT/{IMEI}/a` |
| Client ID | `FOURG_{IMEI}_{epochMillis}` |
| Certificates | fetched from `get_mqtt_certificates.php` (`WebUrlConstants.mqttCertificatesUrl`), cached in secure storage, rotated by version |

## Page-wise commands

For each page and action: the MQTT commands sent to the panel (in order) and the server API call. `PASS` = 6-digit passcode, and every frame starts `ST*{IMEI}$PASS$` and ends `*ED`. Delete sends no command to the panel.

### Add Device Details → Save device

| Step | Command / call | Check | On failure |
| --- | --- | --- | --- |
| 1 | Connect `01$000$00` | Handshake reply within 20 s | Nothing saved, "Device MQTT handshake failed" |
| 2 | Server `addPanel` (`pnl_type 4GCOM`) | Returns `panelAccNo`, `pnlId` | Error toast |
| 3 | Write Device ID `02$013$01${accNo}$000001$000000` → wait 3 s → read `01$013$01` | `parts[6] == accNo` | `deletePanel` rollback, "Device ID verification failed. Device removed." |
| 4 | Write admin `02$008$4#+91#{admin}$0#+91#0` (×10 empty slots) → wait 3 s → read `01$008` | Reply contains admin no. | Rollback, "Admin Number verification failed. Device removed." |
| 5 | Write destination `02$013$02$1$182.73.129.27$05600$0$0.0.0.0$00000` → wait 3 s → read `01$013$02` | Reply contains IP and port | Rollback, "Destination verification failed. Device removed." |
| 6 | `AddPanelSuccess` | — | — |

### Other pages

| Page | Action | MQTT commands to panel (in order) | Server API | On failure |
| --- | --- | --- | --- | --- |
| Device Details | Update (admin unchanged) | None | `updatePanelDataList` (site, address, IMEI, SIM, admin) | Error toast |
| Device Details | Update (admin changed) | New connection: connect `000` → read `008` → write `008` (only slot 0 changed) → wait for ack (8 s) → read `008` to confirm → disconnect `01$000$01` | `updatePanelDataList` only after the panel confirms | Panel not confirmed → nothing saved |
| Device Details | Delete | None | `deletePanel` (two confirmations) | Error toast |
| Panel list card | CONNECT | Opens the dashboard (see below) | — | — |
| Panel list card | Evacuate / Reset / Silence | New connection: connect `000` (8 s cap) → read `01$011$08{n}` → if disabled, write `02$011` with ENABLED=1 → `02$012$08{n}$1` → wait 9 s → `02$012$08{n}$0` → disconnect | — | Not reachable → SMS `< PASS OUTPUT n ON >` then `OFF` |
| Dashboard | Open | Connect `000` → read `01$001` → write `02$011` for any disabled output 1–3 → read `01$001` again if anything was enabled | — | Timeout or wrong password toast |
| Dashboard | Pull to refresh | `01$001` | — | No reply in 10 s → disconnected state |
| Dashboard | Evacuate / Reset / Silence | `02$012$08{1,2,3}$1` → wait 9 s → `02$012$08{n}$0` → `01$001` | — | No reply in 10 s → "Device not responding" |
| Dashboard | App resumed | Connect ping `000` → `01$001`; if no reply, full reconnect (retry once after 2 s) | — | Disconnected state |
| Dashboard | Back / exit | `01$000$01` (disconnect) → close the link | — | — |
| Settings | Open | Connect ping `000` (silent) | — | — |
| Device ID | Open | `01$013$01` | — | Read timeout toast |
| Destination IP | Open / Update | Read `01$013$02`; Update: `02$013$02${type}${ip}${port}$0${ip2}${port2}` → wait for `013` write ack | — | "Failed to update Destination IP" |
| Telephone | Open / Save | Read `01$008`; Save: `02$008` with all 11 slots `ABILITY#CC#NUMBER` → wait for ack (8 s) | `updatePanelDataList` (admin) only after the ack | "Failed to update telephone settings" |
| Zone Mappings | Open / Save | Open: `01$001` (names); Save: `01$010$100${input}` → `02$010` (all 31 fields, new name/enable) → wait for ack 3 s, else re-read `010` to confirm | — | Failure toast |
| Audio | Open / Download | Open: `01$009` (30-slot status); Download: `02$009$01${30-char mask}` → poll `01$009` every 5 s until no slot is `2`/`3` | HTTP: list `GET http://devicecloudlink.com:6001/api/docFile/macId/{IMEI}/GetFiles`, upload `POST http://devicecloudlink.com:6001/api/docFile/macId/{IMEI}` | Timeout toast |

Panic, Arm, Disarm, Alarm/Queue Abort, Sounder Off (001) and Alarm/Event logs (015/016) are built in the service but no page calls them today.

## App flow

A G4 panel is checked and set up on the device before it is saved for good. After that, every screen opens its own MQTT session and closes it on exit.

```
 Add Panel screen ──► Device details form ──► Provisioning
 (pick F02L G4 /       (site, IMEI scan,        (handshake, save, Device ID,
  F04L G4 / FCOM G4)    passcode, admin,         admin no., destination IP;
                        SIM, address)            any fail → server record deleted)
                                                      │ success
                                                      ▼
                                               Panel list card
                                       (CONNECT, Evacuate, Reset, Silence, edit)
              ┌──────────────────────────────┬────────┴───────────────┐
              │ edit icon                    │ card buttons           │ CONNECT
              ▼                              ▼                        ▼
       Device details              Quick action (one-shot)     DEVICE DASHBOARD
       (edit site/SIM/address;     (connect 8 s, enable        (live session, status,
        admin no. via short-        output, pulse ON 9 s       zones; Evacuate O1,
        lived link, panel first)    → OFF; SMS fallback)       Reset O2, Silence O3)
                                                                      │ Settings tile
                                                                      ▼
                                                          Settings (owner only)
                                                          (silent connect ping)
        ┌──────────────┬──────────────┬─────────────┬───────────────┴──┐
        ▼              ▼              ▼             ▼                  ▼
    Device ID    Destination IP   Telephone   Zone mappings          Audio
    013/01       013/02           008         001, 010           009 + HTTP
```

### 1. Add device

1. **Add Panel** (`add_panel.dart`): the user picks a G4 model. A name in `fourGComPanels` opens `AddMqttPanelPage` instead of the TCP/SMS form.
2. **Add Device Details** (`add_mqtt_panel.dart`) checks, in order:
   - Site name: required, ≤ 15 characters, unique.
   - IMEI: exactly 15 digits, unique; QR/barcode scan available.
   - Password: exactly 4 digits.
   - Admin number: exactly 10 digits.
   - Device SIM: 10 or 13 digits, not equal to admin, unique (`+91` stripped for the check).
   - Address: required, ≤ 40 characters.
3. **Provisioning** (`PanelCubit.addPanel`), with a progress dialog "Saving device details...": see the step table above. Server `addPanel` is sent with `panelType: 4GCOM`, `adminCode: 1234`, Tel. No. 1–10 = `0000000000`. Passcode becomes `00` + 4 digits. On success: toast "Device Added Successfully" → back to the list.

### 2. Panel list card

`panel_item.dart` shows a **CONNECT** button for any panel with an IMEI. The edit icon opens `MqttPanelDetailsScreen`.

The card buttons Evacuate / Alarm Reset / Silence drive outputs 1 / 2 / 3 as one-shot actions. Each one asks for confirmation, then:

1. Blocks a second command on the same IMEI ("A command is already running").
2. Opens a new connection and handshake, capped at 8 s.
3. Not reachable → offers SMS `< {pass} OUTPUT {n} ON >` then `OFF` to the device SIM.
4. Reads that output's 011 record and enables it if disabled. It does not read the dashboard, because the backend treats a dashboard read as an app login.
5. Sends output ON, shows "Sent" or "Send Failed", waits 9 s, sends OFF, waits for the queue, then disconnects.

### 3. Device dashboard

`MqttControlScreen` (`mqtt_control_screen.dart`) holds the live session.

- **Open**: connect + handshake (20 s inside the service, 25 s safety timer on the screen). Then, after 1 s, `ensureOutputsEnabled` reads 001 and enables outputs 1–3 if any are disabled. That read also fills the screen.
- **Shows**: signal (NO SIGNAL / MARGINAL / OK / GOOD / EXCELLENT), mains, battery, system state (PANIC / ARMED / DISARMED / NORMAL), zones 1–4 with names and FIRE / NORMAL, and a live clock.
- **Commands**: Evacuate = output 1, Alarm Reset = output 2, Silence Sounder = output 3. Each is pulsed ON for 9 s, then OFF, and the dashboard is read again. Feedback comes from `FourGMqttParser.parseCommandResult`, with a 10 s timeout ("Device not responding").
- **Refresh**: pull to refresh reads 001; no reply in 10 s → disconnected state.
- **Errors**: network error, invalid password or handshake failed, connection timeout. Each is shown as a toast.
- **Background**: after 30 s in the background the link is released and the screen shows RECONNECTING. On resume, a link that is still up is checked with a ping and a 001 read; otherwise the screen reconnects, retrying once after 2 s. The disconnected state shows only if both fail.
- **Exit**: "Exit Device Control?" confirmation → sends 000/01 disconnect → waits 500 ms → closes the broker link. The list shows a "Device Disconnected" toast.
- **Logs** and **Settings** tiles. Settings is blocked for guests (`shareStatus == accepted`) with "Permission Denied".

### 4. Settings

`FourGMqttSettingsScreen` sends a silent connect ping on open; every sub-page reads only what it needs.

| Page | Reads | Writes | Notes |
| --- | --- | --- | --- |
| Device ID | 013/01 | — | Shows the account number set at provisioning |
| Destination IP | 013/02 | 013/02 | Primary + secondary IP/port |
| Telephone | 008 | 008 (all 11 slots) | Ability per slot: SMS / Call / SMS & Call; admin change also updates the server via `AdminNumberSync`; offers to restore the account admin if the panel differs |
| Zone mappings | 001 (fast name list), then 010 for the chosen input | 010 (name + enable) | 2 inputs for F02L G4, else 4; no ack in 3 s → re-read to confirm |
| Audio | 009 status (polled every 5 s while downloading) | 009 download mask | 30 `.amr` slots: pick a file locally → upload to the HTTP server → tell the panel which slots to download |

### 5. Device details

`MqttPanelDetailsScreen` edits the server record. If the admin number changed, it first runs `AdminNumberSync.connectAndWriteToPanel`: a short-lived connection reads 008, swaps slot 0 only, writes, then reads back. The server is updated only after the panel confirms.

## Communication flow

Every exchange is one text frame published to `/b`, and the panel answers on `/a`. A request becomes a success only when a matching reply arrives before its timeout.

### Frame format

```
Request:  ST*{IMEI}${PASSCODE6}${TYPE}${PACKET_ID}[${DATA}...]*ED
Response: ST*{IMEI}${PRODUCT_ID}${TYPE}${STATUS}${PACKET_ID}[${DATA}...]*ED
```

- Split on `$`. `parts[0]` = `ST*{IMEI}`, `parts[2]` = frame type, `parts[3]` = status, `parts[4]` = packet ID. Strip `*ED` from the last field.
- Passcode: the user enters 4 digits; the wire needs 6, left-padded with zeros (`1234` → `001234`). Use `FourGMqttCommands.wirePasscode()`.
- `parts[1]` of a reply is the 3-digit PRODUCT_ID (100–103 for this family). The service caches it per IMEI.

| Frame type | Meaning |
| --- | --- |
| `01` | Read request (app → panel) |
| `02` | Write request (app → panel) |
| `03` | Read response; status `01` = OK |
| `04` | Write response; status below |
| `00` | Error response; `parts[3]` = error code |

| Write status (`04`) | Meaning | Handling |
| --- | --- | --- |
| `01` | Ack | success |
| `02` | Process success | success |
| `04` | Processing | not final, keep waiting |
| `00` | Nack | failure |
| `03` | Process fail | failure |
| `99` | Data error | failure |

| Error code (`00`) | Message |
| --- | --- |
| `01` | Packet type error |
| `02` | Unknown packet ID |
| `03` | Wrong passcode |
| `04` | Wrong IMEI |
| `05` | Device engaged, try again |
| `06` | Login required |

### Packets used by the app

| Packet | Request (after `ST*{IMEI}${PASS}$`) | Purpose | Reply matched on |
| --- | --- | --- | --- |
| 000 connect | `01$000$00*ED` | Handshake / login | `03$01$000`, `parts[5]` ≠ `01` = accepted (it is the firmware version); `01` = rejected |
| 000 disconnect | `01$000$01*ED` | End session | any `000` |
| 001 dashboard read | `01$001*ED` | Signal, mains, battery, panic, arm state, zones, outputs | `03$01$001` |
| 001 panic | `02$001$01*ED` | Panic | write ack |
| 001 alarm abort | `02$001$02*ED` | Abort alarm | write ack |
| 001 queue abort | `02$001$03*ED` | Abort pending queue | write ack |
| 001 disarm / arm | `02$001$04*ED` / `02$001$05*ED` | Disarm / arm | write ack |
| 001 sounder off | `02$001$06*ED` | Silence | write ack |
| 008 telephone | read `01$008*ED`; write `02$008${11 slots}*ED` | Admin + Tel. No. 1–10 | `03$01$008` / `04$xx$008` |
| 009 audio | read `01$009*ED`; write `02$009$01${30-char mask}*ED` | Audio slot status, download to device | `03$01$009` / `04$01or02$009` |
| 010 input settings | read `01$010${INPUT_OF_PRODUCT}${INPUT_NO}*ED`; write = all 31 fields echoed | Zone name / enable | read needs ≥ 38 parts and matching `parts[5]`, `parts[6]` |
| 011 output settings | read `01$011$08{n}*ED`; write = record echoed with ENABLED=1 | Enable output 1–3 | `03$01$011` / `04$xx$011` |
| 012 output control | `02$012$08{n}${1 or 0}*ED` | Output n ON/OFF | `04$xx$012` |
| 013/01 device ID | read `01$013$01*ED`; write `02$013$01${PANEL_ID}$000001$000000*ED` | Panel account number | `03$01$013$01`, ID at `parts[6]` |
| 013/02 destination | read `01$013$02*ED`; write `02$013$02${type}${ip}${port}$0${ip2}${port2}*ED` | Server IP/port (default `182.73.129.27:05600`) | `03$01$013$02` |
| 015 / 016 | `01$015$01*ED` / `01$016$01*ED` | Alarm / event logs | fire-and-forget |

### Payload details

- **Dashboard (001) reply**: `parts[5]` is a status string of single digits: `[0]` signal bars 0–4, `[1..3]` signal %, `[4]` network mode, `[5]` device mode, `[6]` mains, `[7]` battery (`1` = low), `[8]` panic (`1` = panic), `[9]` security (`4` = armed, `5` = disarmed). Mains: `0` = ON for fire panels; `1` = ON for the communicator.
- **Zones** in the 001 reply: the first field containing `|` (optional `D|` prefix), split on `;`. Each item is `status|name`. Position = input number. `1` = FIRE, `D` = disabled, `0` = normal.
- **Outputs** in the 001 reply: the last field, tokens split on `|` or `;`, every other token is a state: `D` disabled, `0` off, `1` on.
- **Telephone slot (008)**: `ABILITY#CC#NUMBER`, 11 slots (slot 0 = admin). Ability `0` disable, `2` SMS, `3` Call, `4` SMS+Call. Empty slot = `0#+91#0`. The panel echoes `-` for a blank country code but rejects it on write; send `+91`, or `NO CODE` when empty.
- **Input settings (010)**: for products 100–103, INPUT_OF_PRODUCT is always `100`, whatever the real product ID. EVENT_LOG (field 21) is always written as `0`. Field order lives in `input_settings.dart`.
- **Audio mask (009)**: 30 characters, one per slot `AUDIO_01.amr`…`AUDIO_30.amr`. Status: `0` none, `1` downloaded, `2` downloading, `3` queued, `9` failed. On write, `1` = download this slot.

### Rules that matter when porting

1. **One request at a time.** The panel drops a second request that arrives before it has answered the first. `FourGMqttService._enqueue` chains requests on `_queueTail`; `service.idle` waits for the queue to empty.
2. **Subscribe before you publish**, so a fast reply is not missed.
3. **Timeouts**: handshake 20 s, queued reads/writes 3 s, direct reads 10 s, admin write ack 8 s.
4. **Verify writes by reading back** when no ack arrives (010, 008, 013, destination).
5. **No library auto-reconnect.** A broker reconnect does not restore the panel session; the caller must redo the 000 handshake.
6. **Output pulse**: Evacuate, Alarm Reset and Sounder Off turn the output ON, then OFF after 9 s (`outputPulseDuration`).

## Code map

The G4 code is four layers: transport, service, repository, then screens. Only the first three need to move to the new app unchanged.

| Layer | File | What it does |
| --- | --- | --- |
| Transport | `lib/core/repo/mqtt_repository.dart` | `MqttServerClient` with TLS context; `connect(imei)` returns a generation number; `subscribe`, `publish` (returns `false` when offline), `listen` → broadcast `messageStream`; `connectionStatusStream`; `disconnectIfCurrent` |
| Certificates | `lib/core/mqtt/certificate_store.dart` | Singleton: memory → secure storage → API; background version check |
| Constants | `lib/constants/mqtt_constants.dart` | Broker, port, topics |
| Frame builders | `lib/features/mqtt/services/fourg_mqtt_commands.dart` | Static payload builders, `wirePasscode`, `outputPulseDuration` |
| Frame parsers | `lib/features/mqtt/services/fourg_mqtt_parser.dart` | Handshake success/reject, error frames, command result, dashboard inputs and outputs |
| Service | `lib/features/mqtt/services/fourg_mqtt_service.dart` | Request queue, `connectAndHandshake`, every read/write with its reply matcher and timeout, `ensureOutputsEnabled`, write-then-verify for 010 |
| Repository | `lib/features/mqtt/repository/fourg_repository.dart` | Thin pass-through the UI and cubit use |
| Admin sync | `lib/features/mqtt/services/admin_number_sync.dart` | Panel-first admin number write, read-back check, then server update |
| Models | `lib/features/mqtt/models/input_settings.dart`, `voice_model.dart` | Packet-010 record; audio slot |
| Audio cache | `lib/features/mqtt/repository/audio_repository.dart` | Local JSON file of audio slots, serialised writes |
| Add device | `lib/features/mqtt/screens/add_mqtt_panel.dart` + `PanelCubit.addPanel` in `lib/presentation/cubit/panel/panel_cubit.dart` | Form, validation, provisioning sequence with rollback |
| Dashboard | `lib/features/mqtt/screens/mqtt_control_screen.dart` | Live session, status parsing, commands, reconnect on resume |
| Settings | `lib/features/mqtt/screens/fourg_mqtt_settings_screen.dart` | Grid: Device ID, Destination IP, Telephone, Zone Mappings, Audio |
| Sub-screens | `fourg_mqtt_telephone_settings_screen.dart`, `fourg_mqtt_zone_mappings_screen.dart`, `fourg_mqtt_audio_settings_screen.dart` | One packet family each |
| Panel list card | `lib/presentation/widgets/panel_item.dart` | CONNECT button; one-shot quick actions with SMS fallback |
| Device details | `lib/presentation/screens/mqtt_panel_details.dart` | Edit details; admin change via `AdminNumberSync.connectAndWriteToPanel` |
| IMEI scan | `lib/features/mqtt/screens/imei_scanner_sheet.dart` | Barcode scanner for the IMEI |

State handling: the add flow uses `PanelCubit` (Bloc) with `PanelLoading` / `AddPanelSuccess` / `AddPanelFailure`. The control and settings screens keep state in `StatefulWidget` fields and create their own `MqttRepository` per screen. Each screen session has its own MQTT connection.

Packages: `mqtt_client`, `flutter_bloc`, `dio` (audio HTTP), `flutter_secure_storage` (certificates), `path_provider`, `toastification`, `logger`.

## Porting guide

Copy the transport, service and repository layers as they are, then rebuild the screens around them. Keep the protocol rules listed above.

1. Add the packages: `mqtt_client`, `flutter_secure_storage`, `dio`, `path_provider`.
2. Copy `mqtt_constants.dart`, `mqtt_repository.dart`, `certificate_store.dart` (with the certificate repo + response and the secure-storage helpers), `fourg_mqtt_commands.dart`, `fourg_mqtt_parser.dart`, `fourg_mqtt_service.dart`, `fourg_repository.dart`, `input_settings.dart` and `admin_number_sync.dart`. Change the `package:fire_nex/` imports.
3. Call `CertificateStore.instance.initialize()` at app start, after login. The certificate API needs the same backend session.
4. Decide how the new app marks a G4 device. Firenex uses a non-empty IMEI plus the model name in `fourGComPanels`, and saves `pnl_type = 4GCOM` on the server.
5. Build the add flow in the order of the step table above, and roll back the server record on any failed check.
6. For the dashboard screen, create one `MqttRepository` per screen, listen to `messageStream` and `connectionStatusStream`, run connect + handshake, then `ensureOutputsEnabled` (outputs 1–3). Read 001 on pull-to-refresh, and pulse outputs for commands. Send 000/01 disconnect on exit.
7. Handle the lifecycle: 30 s background grace, then release the link. On resume, ping + read 001; if that fails, reconnect with a fresh handshake, retrying once after 2 s. Ignore stale results with an attempt ID.
8. For quick actions from a list, use a short-lived connection with an 8 s handshake cap, `ensureOutputsEnabled(viaDashboard: false)`, pulse ON → 9 s → OFF, `await service.idle`, then disconnect. Fall back to SMS `< {pass} OUTPUT {n} ON >` / `OFF` if unreachable.
9. Treat the panel as the source of truth for the admin number: write to the panel, read it back, then update the server.

Things to check before reusing in another app:

- [ ] Whether the new app uses the same AWS IoT endpoint and certificate API, or its own.
- [ ] Whether the destination IP `182.73.129.27:05600` and admin country code `+91` stay hard-coded or become settings.
- [ ] Whether the audio server `devicecloudlink.com:6001` is shared (it is plain HTTP today).
- [ ] Whether guest users (`shareStatus = accepted`) should also be blocked from Settings in the new app.
- [ ] Whether a 001 dashboard read counts as an app login on the backend for the new app too. Firenex avoids it in quick actions because the backend raises an alert on it.
