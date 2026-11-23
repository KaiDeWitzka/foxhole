# fox_netmap

**Interaktive Netzwerkkarte deines Heimnetzes** — scannt das LAN und zeigt alle Geräte als zoombare Karte und durchsuchbare Tabelle.

## Funktionen

- **Netzwerk-Scan:** ARP/NDP (IPv4 + IPv6), optional **TR-064** an der FRITZ!Box (Geräteliste, VPN-Clients, WAN-IP), optional **SNMP** (Switch-Ports, "Verbunden mit")
- **Karte & Tabelle:** Kategorie, IP, IPv6, MAC, Hostname, Hersteller (OUI), offene Ports, "Verbunden mit", VPN-Badge; Suche/Filter, Zoom, Klick-Details, Drag & Drop der Knoten
- **Persistenz:** SQLite-Datenbank im Daten-Volume, zyklische Scans, Historie, Event-Log
- **Exporte:** JSON, CSV, PDF (Karte + Tabelle), Auto-Export, Standorte, Einbettungs-Tokens für externe Dashboards
- **Alarme:** neue Geräte per Webhook / Gotify / Ntfy; VPN-Geräte werden erkannt (kein Alarm)
- **Sicherheit:** optionaler Login (Passwort-Hash in der DB), HTTPS-Cookie-Flag, CSP; Container läuft als **UID 10001, read_only, ohne Capabilities** (nur der Scanner bekommt NET_RAW für ping via setcap)
- **Open Source (MIT):** <https://github.com/KaiDeWitzka/fox_netmap> — UI auf Deutsch, Englisch, Französisch, Spanisch, Italienisch, Portugiesisch

## Hinweise

- Der Scanner-Dienst läuft mit **Host-Netzwerk**, damit er dein echtes LAN sieht (ARP/NDP). Ohne `network_mode: host` sähe er nur das Docker-Netz.
- Netzwerke (CIDR) können in den App-Einstellungen vorgegeben werden; leer = automatische Erkennung. FRITZ!Box-Zugangsdaten sind optional (TR-064).
- Daten liegen unter `${APP_DATA_DIR}/data` (SQLite, Einstellungen, Layout) und bleiben bei Updates erhalten.

---

**fox_netmap** — interactive network map of your home network: scan, map, table, alarms, exports. Open source (MIT): <https://github.com/KaiDeWitzka/fox_netmap>
