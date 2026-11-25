# 4GCOM MQTT Commands

Every command the app publishes to a 4GCOM panel, plus the responses it expects back.
Sources: [fourg_mqtt_commands.dart](../lib/features/mqtt/services/fourg_mqtt_commands.dart), [fourg_mqtt_service.dart](../lib/features/mqtt/services/fourg_mqtt_service.dart), [input_settings.dart](../lib/features/mqtt/models/input_settings.dart), [fourg_mqtt_parser.dart](../lib/features/mqtt/services/fourg_mqtt_parser.dart).

## Topics

| Direction | Topic |
|---|---|
| App → Panel (publish) | `QlMQTT/{IMEI}/b` |
| Panel → App (subscribe) | `QlMQTT/{IMEI}/a` |

## Frame format

```
ST*{IMEI}${PASSCODE}${PACKET_TYPE}${PACKET_ID}[${DATA}...]*ED
```

| Field | Meaning |
|---|---|
| `ST*` / `*ED` | Start / end markers |
| `{IMEI}` | Panel IMEI |
| `{PASSCODE}` | 6 digits, left-padded with zeros (`1234` → `001234`) |
| `PACKET_TYPE` | `01` = Read request, `02` = Write request |
| `PACKET_ID` | 3-digit feature code (see below) |
| `DATA` | Extra fields, separated by `$` |

> **Passcode padding:** the panel rejects anything other than a 6-digit passcode with error `03` (Wrong passcode). Builders in `FourGMqttCommands` and packet 010 pad automatically. The builders for packets 008, 009, and 013 in `fourg_mqtt_service.dart` send the passcode exactly as they receive it, so the caller has to pass it pre-padded.

---

## Session (packet 000)

| Command | Payload |
|---|---|
| Connect (login) | `ST*{IMEI}${PASS}$01$000$00*ED` |
| Disconnect (logout) | `ST*{IMEI}${PASS}$01$000$01*ED` |

**Connect response**
- Accepted: `ST*{IMEI}${..}$03$01$000${FIRMWARE_VERSION}...`, where the 6th field is anything other than `01`
- Rejected: `ST*{IMEI}${..}$03$01$000$01...`

## Dashboard (packet 001)

| Command | Payload |
|---|---|
| Read dashboard | `ST*{IMEI}${PASS}$01$001*ED` |
| Panic (no longer used by the Evacuate button; see packet 012) | `ST*{IMEI}${PASS}$02$001$01*ED` |
| Alarm abort | `ST*{IMEI}${PASS}$02$001$02*ED` |
| Queue abort | `ST*{IMEI}${PASS}$02$001$03*ED` |
| Disarm | `ST*{IMEI}${PASS}$02$001$04*ED` |
| Arm | `ST*{IMEI}${PASS}$02$001$05*ED` |
| Sounder off | `ST*{IMEI}${PASS}$02$001$06*ED` |

**Dashboard read response:** `ST*{IMEI}${..}$03$01$001$...$D|{status}|{name};{status}|{name};...`
Input status: `D` = Disabled, `0` = Normal, `1` = Alert. Position in the list = input number.

## Telephone / admin numbers (packet 008)

| Command | Payload |
|---|---|
| Read telephone settings | `ST*{IMEI}${PASS}$01$008*ED` |
| Write admin numbers | `ST*{IMEI}${PASS}$02$008${N1}${N2}...${N11}*ED` |

Each number entry has the form `{FLAG}#{COUNTRY_CODE}#{NUMBER}`. Unused slots are `0#+91#0`.
Single-admin example (slot 1 set, 10 empty slots):

```
ST*{IMEI}${PASS}$02$008$4#+91#9876543210$0#+91#0$0#+91#0$0#+91#0$0#+91#0$0#+91#0$0#+91#0$0#+91#0$0#+91#0$0#+91#0$0#+91#0*ED
```

## Audio (packet 009)

| Command | Payload |
|---|---|
| Read audio status | `ST*{IMEI}${PASS}$01$009*ED` |
| Write audio download | `ST*{IMEI}${PASS}$02$009$01${DOWNLOAD_MASK}*ED` |

The write ack can come back as `04` (Processing). That status is not final, so the app keeps waiting for a second message.

## Input settings (packet 010)

| Command | Payload |
|---|---|
| Read input | `ST*{IMEI}${PASS}$01$010${PRODUCT_NO}${INPUT_NO}*ED` |
| Write input | `ST*{IMEI}${PASS}$02$010${PRODUCT_NO}${INPUT_PACKET_ID}${FIELDS...}*ED` |

`PRODUCT_NO`: products `100`–`103` (basic family) all use `100`.

Write fields, in order, separated by `$`:

```
ENABLED, NAME, ZONE_TYPE, SENSOR_TYPE, EVENT_ID,
ALERT_EN, ALERT_CODE, RESTORAL_EN, RESTORAL_CODE,
ARM_EN, ARM_CODE, DISARM_EN, DISARM_CODE,
CMS1, CMS2, FAILOVER, PENDING_QUEUE, SMS, CALL,
ALARM_LOG, EVENT_LOG (always 0),
OUTPUT_EN, OUTPUT_MAPPING, OUTPUT_CONTROL_MODE, PULSE_DURATION,
AUDIO_CALL_EN, AUDIO_CALL_FILE, ANNOUNCE_EN, ANNOUNCE_FILE, ANNOUNCE_COUNT,
TELE_NO_MAPPING
```

## Output control (packet 012)

| Button | ON payload | OFF payload (sent 9 s later) |
|---|---|---|
| Evacuate (Output 1) | `ST*{IMEI}${PASS}$02$012$081$1*ED` | `ST*{IMEI}${PASS}$02$012$081$0*ED` |
| Alarm Abort (Output 2) | `ST*{IMEI}${PASS}$02$012$082$1*ED` | `ST*{IMEI}${PASS}$02$012$082$0*ED` |
| Sounder Off (Output 3) | `ST*{IMEI}${PASS}$02$012$083$1*ED` | `ST*{IMEI}${PASS}$02$012$083$0*ED` |

Output numbers are `081`–`084` (Outputs 1–4). The state is `1` = ON or `0` = OFF. Each button turns its output ON and then the app turns it OFF again after 9 seconds (`FourGMqttCommands.outputPulseDuration`). A write status of `04` (Processing) is not final, so the app keeps waiting for the next message. The panel answers `$04$00` (NACK) if the output is disabled in Output Settings.

**One request at a time:** the panel silently drops a request that arrives before it has answered the previous one. The app therefore queues dashboard reads, output ON/OFF, Output Settings reads/writes and the logout, and sends each one only after the previous one has been answered (or after 3 s with no answer).

**Auto-enable on connect:** after connecting, the app reads the dashboard. For each of Outputs 1–3 marked `D`, it reads `$01$011$08N`, writes the same record back with `ENABLED` set to `1` (`$02$011$08N...`), and waits for the `$04$..$011` ack. The panel card does this only for the output whose button was pressed.

## Panel ID and destination (packet 013)

| Command | Payload |
|---|---|
| Read panel ID | `ST*{IMEI}${PASS}$01$013$01*ED` |
| Assign panel ID | `ST*{IMEI}${PASS}$02$013$01${PANEL_ID}$000001$000000*ED` |
| Read destination | `ST*{IMEI}${PASS}$01$013$02*ED` |
| Write destination | `ST*{IMEI}${PASS}$02$013$02${TYPE}${IP1}${PORT1}$0${IP2}${PORT2}*ED` |

Default destination values: `TYPE=1`, `IP1=182.73.129.27`, `PORT1=05600`, `IP2=0.0.0.0`, `PORT2=00000`.

## Logs (packets 015 / 016)

| Command | Payload |
|---|---|
| Read alarm logs | `ST*{IMEI}${PASS}$01$015$01*ED` |
| Read event logs | `ST*{IMEI}${PASS}$01$016$01*ED` |

---

## Responses from the panel

### Response frame types (3rd field)

| Code | Meaning |
|---|---|
| `00` | Error response |
| `03` | Read response (`03$01$...`) |
| `04` | Write response: `ST*{IMEI}${..}$04${STATUS}${PACKET_ID}*ED` |

### Error codes (frame type `00`)

| Code | Meaning |
|---|---|
| `01` | Packet type error |
| `02` | Unknown packet ID |
| `03` | Wrong passcode |
| `04` | Wrong IMEI |
| `05` | Device engaged, try again |
| `06` | Login required |

### Write status codes (frame type `04`)

| Code | Meaning | Treated as |
|---|---|---|
| `00` | Nack | Failure ("Rejected by device") |
| `01` | Ack | Success |
| `02` | Process success | Success |
| `03` | Process fail | Failure |
| `04` | Processing | Success on packet 001; still waiting on 009 and 012 |
| `99` | Data error | Failure |

Some firmware confirms a dashboard command (packet 000 or 001) with a read response (`03$01`) instead of a write ack. The app counts that as success.
