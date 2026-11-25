# FogShield — manual test checklist

Run on a real Android phone **and** a real iPhone before each release, with a **test account** and **test panels** only (never a customer's panel). Mark each line ✅ / ❌ with a note. The automated suite (`flutter test`) covers the logic; this list covers what needs real hardware, networks and SMS.

Tester: ____  Date: ____  App version: ____  Android device: ____  iPhone: ____

## 1. Account

| # | Do | Expected | Android | iOS |
|---|---|---|---|---|
| 1.1 | Sign up with a new mobile number | "Signup" success message, back to login | | |
| 1.2 | Log in | Panel list opens; a push permission prompt on first run | | |
| 1.3 | Log in with a wrong password | Error message, stays on login | | |
| 1.4 | Forgot password | Server message shown | | |
| 1.5 | Profile → change name / email / mobile | Saved; mobile change asks to log in again | | |
| 1.6 | Log out, log in as **another** test user | Only the second user's panels show, never the first user's (not even for a moment) | | |
| 1.7 | Kill and reopen the app while logged in | Splash → panel list, no login | | |

## 2. Panel list and offline

| # | Do | Expected | Android | iOS |
|---|---|---|---|---|
| 2.1 | Open the list, pull to refresh | All panels; filter by type works | | |
| 2.2 | Airplane mode → reopen the list | Cached panels show | | |
| 2.3 | Airplane mode → add a FogShield panel → "Save Offline" | "Saved Offline."; panel in the list | | |
| 2.4 | Turn network back on → refresh twice quickly | The offline panel appears on the server **once** (check the web/DB) | | |
| 2.5 | Airplane mode → rename a panel → network on → refresh | Name kept, server has the new name | | |
| 2.6 | Airplane mode → delete a panel → network on → refresh | Gone from the server | | |

## 3. FogShield (SR1) panel

| # | Do | Expected | Android | iOS |
|---|---|---|---|---|
| 3.1 | Add panel → FogShield Pro → IP, port, password, SIMs → Save | Connects, reads MAC/version/account no., panel saved | | |
| 3.2 | Add while another app holds the panel | "Already connected" dialog → disconnect → saves | | |
| 3.3 | Static IP set to an address that accepts but doesn't answer, local IP correct → Extended View | Connects through the local IP (after ~4 s) | | |
| 3.4 | Extended View: dashboard | Date/time ticks; arm status, zones, outputs, mains, signal match the panel | | |
| 3.5 | Panel mains code 9, or panel clock at 10:09 | Arm status still correct; zones still update | | |
| 3.6 | Trigger fogger / Alarm reset / Sounder off from the card (IP) | "Successful" | | |
| 3.7 | Same with the panel's IP unreachable (IP-GSM panel) | Offers SMS → sends `< 1234 OUTPUT n ON >` then `OFF` | | |
| 3.8 | Dashboard: automation on/off, pulse, sounder off, sync time | Each acts on the panel; toast matches | | |
| 3.9 | Leave the dashboard | Panel shows the app disconnected | | |
| 3.10 | Stay idle on the dashboard | Inactivity warning, then auto-disconnect | | |

## 4. More settings (SR1)

| # | Do | Expected | Android | iOS |
|---|---|---|---|---|
| 4.1 | Panel ID / Local IP / Destination IP: read and update | Values match the panel; update confirmed | | |
| 4.2 | Telephone numbers: read, edit 2 slots, save | Panel holds the new numbers + alert types | | |
| 4.3 | Telephone numbers with the panel offline | "fetch failed" toast; **Save refuses** and the panel's numbers are unchanged | | |
| 4.4 | Leave the telephone screen while it is loading | No error | | |
| 4.5 | Panel ID with the panel unreachable over IP | "Panel not reachable over IP… only be read over IP"; **no SMS offered** | | |

## 5. Panel details

| # | Do | Expected | Android | iOS |
|---|---|---|---|---|
| 5.1 | Edit site name / address / SIM / admin number | Saved on the server | | |
| 5.2 | Delete (IP reachable) | Panel reset over IP, removed from the list | | |
| 5.3 | Delete (IP unreachable) → SMS → "Remove from App?" | Removed from the list | | |

## 6. Logs and vendor

| # | Do | Expected | Android | iOS |
|---|---|---|---|---|
| 6.1 | Logs for a panel | List with event names and times | | |
| 6.2 | Export PDF → open | File saved (Android: Documents/fogshield/logs; iOS: Files → app → fogshield/logs) and opens | | |
| 6.3 | Logs offline | Last cached logs | | |
| 6.4 | Vendor: add, view, delete | Works; vendor profile shows the data | | |

## 7. Push notifications

| # | Do | Expected | Android | iOS |
|---|---|---|---|---|
| 7.1 | Trigger an alarm on a test panel, app in foreground | Toast with site / event / time | | |
| 7.2 | Same with the app in background / killed | System notification; tapping opens the app | | |

## 8. G4 (4G / MQTT) devices

Full flow and expected commands: [G4_MQTT_FLOW.md](G4_MQTT_FLOW.md); details in [PLAN_G4_IMPORT.md](PLAN_G4_IMPORT.md) Steps 1.7, 2.2, 3.1.

| # | Do | Expected | Android | iOS |
|---|---|---|---|---|
| 8.1 | Add Panel → 4G (MQTT) DEVICES → F04L G4; scan the IMEI | "Device Added Successfully"; Device ID, admin no. and destination read back | | |
| 8.2 | Same with a wrong password | "Device MQTT handshake failed"; nothing saved | | |
| 8.3 | Card: Evacuate / Alarm Reset / Silence | "Sent"; output ON then OFF ~9 s later; one push | | |
| 8.4 | Card command with the device offline | After ~8 s, SMS offer | | |
| 8.5 | CONNECT → dashboard, pull to refresh, each command, background > 30 s and back, Back | Live status; reconnects; "Device Disconnected" | | |
| 8.6 | Settings: Device ID, Destination IP, Telephone, Zone Mappings, Audio | Each reads/writes the device | | |
| 8.7 | Device details: change admin number | Device updated first, then the server | | |

## Sign-off

All lines ✅ on both phones, or each ❌ has a ticket: ____ / ____ / ____
