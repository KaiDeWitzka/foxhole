# fox_netmap

**Interaktive Netzwerkkarte deines Heimnetzes** — scannt das LAN und zeigt alle Geräte als zoombare Karte und durchsuchbare Tabelle.

## Funktionen

- **Netzwerk-Scan:** ARP/NDP (IPv4 + IPv6), optional **TR-064** an der FRITZ!Box (Geräteliste, VPN-Clients, WAN-IP), optional **SNMP** (Switch-Ports, "Verbunden mit")
- **Karte & Tabelle:** Kategorie, IP, IPv6, MAC, Hostname, Hersteller (OUI), offene Ports, "Verbunden mit", VPN-Badge; Suche/Filter, Zoom, Klick-Details, Drag & Drop der Knoten
- **Persistenz:** SQLite-Datenbank im Daten-Volume, zyklische Scans, Historie, Event-Log
- **Exporte:** JSON, CSV, PDF (Karte + Tabelle), Auto-Export, Standorte, Einbettungs-Tokens für externe Dashboards
- **Alarme:** neue Geräte per Webhook / Gotify / Ntfy; VPN-Geräte werden erkannt (kein Alarm)
- **Sicherheit:** optionaler Login (PBKDF2-Hash in der DB), Security-Header/CSP, Secrets nie per API im Klartext; Container läuft als **UID 10001, read_only, ohne Capabilities** (nur der Scanner bekommt `NET_RAW` für ping via setcap); `/docs` und `/openapi.json` sind abgeschaltet
- **Datenschutz:** Online-OUI-Fallback default **aus** (MAC-Präfixe gingen sonst an Dritte); Löschfristen für Historie/Ereignisse/Geräte konfigurierbar
- **Open Source (MIT):** <https://github.com/KaiDeWitzka/fox_netmap> — Doku (Handbuch in 6 Sprachen, Sicherheitskonzept, Datenschutz, Betrieb/Architektur) im Repo unter `docs/`

## Hinweise

- Der Scanner-Dienst läuft mit **Host-Netzwerk**, damit er dein echtes LAN sieht (ARP/NDP). Ohne `network_mode: host` sähe er nur das Docker-Netz.
- Netzwerke (CIDR) können in den App-Einstellungen vorgegeben werden; leer = automatische Erkennung. FRITZ!Box-Zugangsdaten sind optional (TR-064).
- Daten liegen unter `${APP_DATA_DIR}/data` (SQLite, Einstellungen, Layout, `initial-admin-password.txt` falls kein Login-Passwort gesetzt) und bleiben bei Updates erhalten.
- **Login:** ohne gesetztes Passwort wird beim ersten Start ein Zufallspasswort in `initial-admin-password.txt` im Daten-Volume abgelegt (Rechte 0600, nicht im Log).
- **TR-064 über HTTPS:** FRITZ!Box-URL `https://fritz.box:49443` setzen und die Option „TLS-Zertifikatsprüfung abschalten" aktivieren (selbstsigniertes Zertifikat) — nur im eigenen LAN, MITM-Risiko. Bei TLS-Fehlern fällt TR-064 auf HTTP zurück und loggt **WARN je Lauf mit Port-Hinweis 49443** (Restrisiko siehe Sicherheitskonzept §4 im Repo); ohne HTTPS bleibt TR-064 auf `http://…:49000` (nur aus dem LAN erreichbar, Digest-Auth).
- **SNMP:** seit v1.6.0 gibt es keine Standard-Community mehr — ohne gesetzte read-only Community wird kein SNMP abgefragt.
- **Image-Pull:** solange das GitHub-Repository privat ist, braucht der Pull aus `ghcr.io` ein Token mit `read:packages`.
