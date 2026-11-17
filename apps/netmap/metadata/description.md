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
  Gateway zugeordnet.
- **FRITZ!Repeater-IPs** (kommagetrennte IPs aus der Mesh-Übersicht) und **SNMP-Switch-IPs**
  pflegst du im Menü **„Einstellungen“** der Webseite (s. u.) – nicht mehr in den
  Runtipi-App-Einstellungen. WLAN-Clients werden so dem jeweiligen Repeater zugeordnet.
- **SNMPv2c (CAM-Tabelle):** `NETZ_SNMP_COMMUNITY` (Standard: `public`) in den App-Einstellungen,
  Switch-IPs optional im Menü „Einstellungen“ (leer = alle als Switch erkannten Geräte).
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
- **Scanner startet nicht / `entrypoint.sh` fehlt:** tritt auf, wenn das Skript-Mount ins Leere zeigt (z. B. nach manuellem Compose-Eingriff). Fix: App normal über den Store aktualisieren und neu starten – v1.9.1 mountet wieder `${APP_DATA_DIR}/data/app` plus das `apps/`-Verzeichnis.

## Quelle

Scanner & Karten-Generator: [KaiDeWitzka/netmap](https://github.com/KaiDeWitzka/netmap)
