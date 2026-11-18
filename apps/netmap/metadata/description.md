# Netmap – Netzwerkkarte deines Netzwerks

Scannt dein lokales Netzwerk und zeigt eine **interaktive Karte** aller gefundenen Geräte als Webseite:

- **Netzkomponenten**: Router/Gateway, verwaltete Switche & Access Points
- **Server/NAS und Clients** (anhand typischer Ports und Hersteller erkannt)
- **Smart-Home/IoT-Geräte** (Espressif, Tuya, Philips Hue, Shelly, Sonoff …) und **Drucker**
- Pro Gerät: **IP-Adresse, MAC-Adresse, Hostname, Hersteller (OUI), offene Ports, Kategorie**
  sowie **„Verbunden mit“** (an welchem Router/Switch das Gerät hängt)

Die Karte (eine einzige HTML-Datei, ohne externe Abhängigkeiten) wird **zyklisch neu gescannt** und ist
interaktiv: Zoom/Pan, Klick auf ein Gerät für Details (bei Router/Switch inkl. Liste der
**angeschlossenen Geräte**, in der Karte hervorgehoben), Suche, Kategoriefilter und Tabellenansicht.

## Hinweise

- Der Scanner-Container läuft im **Host-Netzwerkmodus** (`NET_RAW`/`NET_ADMIN`), damit MAC-Adressen
  per ARP aufgelöst werden können. Ohne eigene IP sind unmanaged Switche/Hubs nicht sichtbar.
- **Subnetz** und **Scan-Intervall** sind in den App-Einstellungen von Runtipi konfigurierbar
  (`NETZ_SUBNET`, z. B. `192.168.178.0/24`; `NETZ_SCAN_INTERVAL` in Sekunden, Standard 900).
- Die Ergebnisse liegen unter `data/web/` (`netzwerkkarte.html` + `scan.json`).
- **App-Update läuft in-place** (kein Löschen/Neuinstallieren nötig): Runtipi kopiert den `data/`-Ordner des
  App-Repos nur bei der **Erstinstallation** nach `${APP_DATA_DIR}/data`. Damit Updates trotzdem sofort greifen,
  mounten die Container zusätzlich das `apps/`-Verzeichnis der Runtipi-Installation und übernehmen beim Start
  automatisch die frischen Skripte aus `apps/<store>/netmap/app/` (Fallback: die `data/app`-Kopie).
  Laufzeitdaten (`scan.json`, `web/`, `certs/`, `config/` mit `topology.json` + `settings.json` aus dem Web-Menü
  „Einstellungen“) liegen persistent in `${APP_DATA_DIR}/data` und überleben Update, Start/Stop **und** sogar das
  Löschen der App, sofern Runtipi beim Löschen „Daten behalten“ gewählt wird. Auch die App-Einstellungen
  (`NETZ_*`) bleiben bei Update/Stop erhalten – nur ein echtes Löschen der App (ohne „Daten behalten“) entfernt sie.

## Exporte (PDF, CSV, Markdown, JSON)

Im Menü **„Einstellungen“** der Webseite (Feld „Exporte erzeugen“, z. B. `all` oder `pdf,csv,md`)
werden bei jedem Scan zusätzliche Exporte nach `data/web/` geschrieben und in der Karte oben
rechts als Download-Buttons angezeigt: `netzwerkkarte.pdf` (A4 quer, reine Standardbibliothek),
`netzwerkkarte.csv`, `netzwerkkarte.md` sowie `scan.json` (JSON, immer vorhanden). Erreichbar z. B.
über `https://<runtipi-host>:8399/netzwerkkarte.pdf`.

## Topologie: wer hängt an welchem Gerät?

In der Karte zeigt jeder Router/Switch/Repeater seine **angeschlossenen Geräte** (Klick hebt sie
hervor; Panel und Tabelle zeigen „Verbunden mit“). Automatisch über die App-Einstellungen:

- **WAN-IP + Verbindungsstatus:** liest die Box zusätzlich per TR-064 (`WANIPConnection`)
  aus – erscheint als Caption am **Internet-Knoten** der Karte (z. B. „Connected · 84.x.x.x“),
  im Klick-Panel des Internet-Knotens, in `scan.json` (`wan`) und in den MD/PDF-Exporten.
- **FRITZ!Box per TR-064:** `NETZ_FRITZ_URL`, `NETZ_FRITZ_USER`, `NETZ_FRITZ_PASS` in den
  App-Einstellungen (TR-064 in der Box aktivieren: *Heimnetz → Netzwerk → Netzwerkeinstellungen
  → „Anwendungen im Heimnetz erlauben (TR-064)“*). WLAN-Clients direkt an der Box werden dem
  Gateway zugeordnet. **Fallback:** schlägt die Abfrage per `https://` fehl (z. B. Anmeldung
  nur per HTTP erlaubt), probiert der Scanner automatisch `http://` (gilt für Hosts- und WAN-Abfrage).
- **FRITZ!Repeater-IPs** (kommagetrennte IPs aus der Mesh-Übersicht) und **SNMP-Switch-IPs**
  pflegst du im Menü **„Einstellungen“** der Webseite (s. u.) – nicht mehr in den
  Runtipi-App-Einstellungen. WLAN-Clients werden so dem jeweiligen Repeater zugeordnet.
- **SNMPv2c (CAM-Tabelle):** `NETZ_SNMP_COMMUNITY` (Standard: `public`) in den App-Einstellungen,
  Switch-IPs optional im Menü „Einstellungen“ (leer = alle als Switch erkannten Geräte).
  Ob SNMP überhaupt abgefragt wird, stellst du in den **Runtipi-App-Einstellungen** ein
  („SNMP-Scan aktivieren“, `NETZ_SNMP_ENABLED`, default an). Aus = Scan nur per Ping/TCP/ARP/TR-064.
  Liest die MAC→Port-Tabelle (`dot1dTpFdbTable`) — funktioniert nur bei SNMP-fähigen
  verwalteten Switchen (z. B. TL-SG3xxx, Netgear GSxxxE, MikroTik, UniFi), **nicht** beim
  TL-SG108E (kein SNMP in irgendeiner Firmware).

In der Karte hängt außerdem jedes Gerät als Caption unter seinem Namen, an welchem Gerät es
angeschlossen ist („→ switch-wohnzimmer (192.168.178.2)“) – dieselbe Info wie die Spalte
„Verbunden mit“ in der Tabellenansicht.

**Manuelle Ergänzungen** (z. B. für den TL-SG108E) und alle weiteren Einstellungen pflegst du direkt
in der Webseite über das **Menü „Einstellungen“** (oben rechts neben Karte/Tabelle): Mapping
`{"192.168.178.40": "192.168.178.2"}` (IP oder MAC → Parent-IP), LAN-Parent für kabelgebundene
Clients, Repeater-IPs, SNMP-Switch-IPs und Exporte. Wird nach `${APP_DATA_DIR}/data/config/`
(`topology.json` + `settings.json`) gespeichert und beim nächsten Scan wirksam — dafür ist **keine
Datenbank** nötig, die Dateien unter `data/` reichen (Runtipi sichert `APP_DATA_DIR` mit den
App-Backups). Ergebnis in der Karte: „Switch <IP> Port <N> (SNMP)“ bzw. „manuell zugeordnet“.

## Einstellungen in der Webseite (ab v1.10.0)

Im Menü **„Einstellungen“** der Karte (oben rechts):

- **Manuelles Topologie-Mapping** (`topology.json`), **LAN-Parent**, **FRITZ!Repeater-IPs**,
  **SNMP-Switch-IPs** und **Exporte** wie bisher (siehe Abschnitte oben).
- **Switch-IPs**: kommagetrennte IPs deiner Switche (z. B. `192.168.178.2,192.168.178.3`) – diese
  Geräte werden in der Karte immer als **Switch** angezeigt (unabhängig von der automatischen
  Erkennung und unabhängig von den SNMP-Switch-IPs). Leer = automatische Erkennung.
- **Export-Format + „Exportieren“-Button**: Auswahlfeld (PDF / CSV / Markdown / JSON / alle / nur
  scan.json+HTML) als Default für jeden Scan **und** ein Button, der den **letzten Scan sofort**
  im gewählten Format exportiert (`POST /api/export`) – die Dateien landen in `data/web/` und
  erscheinen oben rechts als Download-Buttons.
- **Subnetze / VLANs scannen**: kommagetrennt (z. B. `192.168.178.0/24,10.0.10.0/24`); leer = lokales
  Subnetz. Wirkt ab dem nächsten Scan (gleiches Feld gibt es auch in den Runtipi-App-Einstellungen als `NETZ_SUBNETS`).
- **Alarm bei neuem Gerät**: Webhook-URL (POST JSON), Gotify-URL + Token, Ntfy-Topic-URL + Token
  (auch als `NETZ_NOTIFY_*` in den Runtipi-App-Einstellungen).
- **Historie behalten (Stunden)**: Online/Offline-Verlauf (`history.jsonl`) wird nach dieser Zeit
  getrimmt (Standard 720 = 30 Tage).
- **Theme**: Hell/Dunkel – wird sofort umgeschaltet und in `settings.json` gespeichert
  (oder `NETZ_THEME` in den App-Einstellungen bzw. `?theme=light` an die URL).

## In WikiJS einbetten

**WikiJS 3.x** hat keinen HTML-Editor mehr (nur noch Markdown, AsciiDoc, Visuell) — die Karte wird
daher in eine **Markdown-Seite** als raw HTML eingebettet. Dafür einmalig unter
*Administration → Rendering → HTML → Security* **„Sanitize HTML“ deaktivieren** und
**„Allow iframes“ aktivieren** (ab WikiJS 3.1.x empfohlen), dann einfügen
(Port laut Runtipi-App, hier 8399):

```html
<iframe src="https://<runtipi-host>:8399/netzwerkkarte.html" style="width:100%; height:900px; border:0; border-radius:8px;"></iframe>
```

Alternativ ohne iframe: normaler Markdown-Link auf `https://<runtipi-host>:8399/netzwerkkarte.html`.

## HTTPS / SSL

Der Container spricht auf `internal_port` (8080) **plain HTTP** - Runtipi/Traefik routet HTTP
dorthin; TLS im Container wuerde **502 Bad Gateway** erzeugen (wurde in v1.7.1 gefixt).

HTTPS fuer den Aufruf (und das WikiJS-iframe, damit kein Mixed-Content blockiert) wird am **Edge**
terminiert, z. B.:

- Runtipi **"Local SSL certificates"** bzw. die App mit TLS exponieren, oder
- ein Reverse Proxy wie **Nginx Proxy Manager** vor der App.

Dann erreichst du die Karte z. B. als `https://<runtipi-host>:8399/netzwerkkarte.html` (oder ueber
eine eigene Domain) und kannst sie bedenkenlos in HTTPS-WikiJS einbetten.

## Troubleshooting

- **502 Bad Gateway:** Kam in v1.6.x/1.7.0 vor, wenn der Container TLS auf Port 8080 sprach oder
  auf die erste Scan-Datei wartete. Ab v1.7.1 startet der Web-Container sofort mit plain HTTP.
  Pruefen: `docker logs netmap` (Web-UI) und `docker logs netmap-scanner` (Scan).
- **TR-064-Fehler "unknown url type":** `NETZ_FRITZ_URL` muss das Schema enthalten
  (`http://192.168.178.1:49000`); ab v1.7.1 wird ein fehlendes `http://` automatisch ergaenzt.
- **Docker-172.x-Geraete in der Karte:** ab v1.7.1 werden ARP-Eintraege anderer Interfaces
  (z. B. Docker-Bridges) herausgefiltert - nur das gescannte Subnetz landet in der Karte.
- Nach einem App-Update ist **kein** Neuinstallieren nötig (Skripte werden beim Start aus `apps/.../netmap/app` aktualisiert, Daten bleiben in `app-data` erhalten).
- **Scanner startet nicht / `can't open /opt/netzwerkkarte/entrypoint.sh` (Crashloop):** tritt auf, wenn `data/app` nie nach `app-data` kopiert wurde (Runtipi kopiert `data/` nur bei der Erstinstallation, nicht beim Update). Fix ab **v1.9.2**: Der Entrypoint bootstrapped sich selbst und kopiert die Skripte aus dem installierten App-Ordner (`apps/<store>/netmap/app`, Mount `/runtipi-apps`). Einfach App-Update in Runtipi durchführen und neu starten – kein Neuinstallieren nötig.
- **404 auf `/`:** ab v1.9.2 leitet der Webserver `/` per 302 auf `/netzwerkkarte.html` um.

## Neu in v1.10.0 (WatchYourLAN-Features)

- **Alarm bei neuem/unbekanntem Gerät** („jemand ist in meinem WLAN“): Nach jedem Scan wird
  `seen.json` mit dem Scan abgeglichen. Neue Geräte werden in der Karte/Tabelle mit einem
  🆕-Badge markiert und per **Webhook** (POST JSON), **Gotify** oder **Ntfy** gemeldet.
  Konfiguriert in den Runtipi-App-Einstellungen (`NETZ_NOTIFY_WEBHOOK`, `NETZ_NOTIFY_GOTIFY` +
  `NETZ_NOTIFY_GOTIFY_TOKEN`, `NETZ_NOTIFY_NTFY` + `NETZ_NOTIFY_NTFY_TOKEN`) oder im Web-Menü
  „Einstellungen“. Webhook-Payload: `{"event":"new_devices","devices":[{ip,mac,hostname,vendor,category,ports}],...}`.
- **Langzeit-Historie online/offline pro Gerät**: `history.jsonl` in `data/web/` (eine JSON-Zeile pro
  Scan, alle bekannten Geräte mit `online: true/false`, Trim nach `NETZ_HISTORY_HOURS`, Standard 720 h).
  Dazu `first_seen`/`last_seen` pro Gerät in `scan.json`, im Klick-Panel („Erstmals gesehen“ /
  „Zuletzt online“) und als Tabellenspalte „Zuletzt online“.
- **REST-API & Metriken für Grafana**: der Webserver auf Port 8399 liefert zusätzlich
  `GET /api/devices` (alle Geräte aus scan.json), `GET /api/history?limit=N` (Online/Offline-Verlauf),
  `GET /api/health`, `GET /api/config` und **`GET /metrics`** (Prometheus-Textformat:
  `netmap_devices_total`, `netmap_devices{category=...}`, `netmap_device_online{ip,...}`,
  `netmap_scan_timestamp_seconds`, `netmap_new_devices_total`). Prometheus scrapt
  `http://<runtipi-host>:8399/metrics`. Optional pusht der Scanner außerdem nach jedem Scan an
  **InfluxDB2** (`NETZ_INFLUX_ENABLE` + `NETZ_INFLUX_ADDR/BUCKET/ORG/TOKEN`) – in Grafana z. B.
  Online-Zeitanteil pro Gerät.
- **Multi-Subnetz / VLAN-Scan**: `NETZ_SUBNETS` in den App-Einstellungen (kommagetrennt,
  z. B. `192.168.178.0/24,10.0.10.0/24`) – alle Subnetze landen in **einer** Karte
  (`subnets` in `scan.json`, Anzeige in der Kopfzeile).
- **Theme hell/dunkel**: `NETZ_THEME` (`dark`/`light`), Web-Menü „Einstellungen“ oder
  `?theme=light` an die Karten-URL.

## Quelle

Scanner & Karten-Generator: [KaiDeWitzka/netmap](https://github.com/KaiDeWitzka/netmap)
