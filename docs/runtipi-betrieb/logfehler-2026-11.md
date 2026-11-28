# Fehleranalyse: runtipi-Logs 2026-11 (cloud.yumachi.de)

- **Datum:** 2026-11-27
- **Auslöser:** Log-Auszug `runtipi-reverse-proxy` und `runtipi-queue` (2026-11-13 bis 2026-11-27)
- **Ziel:** jede Fehlerklasse verstehen, beheben und nachhalten; die Repos bleiben privat, es wird nichts öffentlich gestellt
- **Skripte dazu:** `scripts/prune-stale-acme-certs.sh`, `scripts/find-stale-traefik-routers.sh` (laufen auf dem Runtipi-Host)

## 1. Übersicht der Meldungen

| Klasse | Log-Muster | Bewertung |
| --- | --- | --- |
| A | `Error renewing ACME certificate: {neko.cloud.yumachi.de []} ... DNS problem: NXDOMAIN ...` | störend (Log-Spam, Let's-Encrypt-Rate-Limit), behebbar |
| B | `error="middleware \"runtipi@docker\" does not exist" entryPointName=websecure routerName=sshwifty-migrated@docker` | störend, App nicht erreichbar |
| C | `Cannot retrieve the ACME challenge for cloud.yumachi.de (token "makeasmtp.php")` | harmlos (Bot-Scan), keine Maßnahme |
| D | `runtipi-queue`: RabbitMQ-Boot nach unclean shutdown, `dropped 0/0/0 ... messages` | normal, kein Datenverlust |

Die Fehler A und B wiederholen sich täglich bzw. bei jedem Request auf die betroffene App.

## 2. Klasse A: stale ACME-Zertifikate (NXDOMAIN)

**Betroffene Domains:** `neko`, `chatai`, `chat`, `code`, `bookmarks`, `cal`, `heim` `.cloud.yumachi.de`

**Ursache:** Diese Apps gab es früher einmal (ihre Subdomains sind im DNS inzwischen NXDOMAIN,
d. h. die Einträge existieren nicht mehr). Traefik speichert ausgestellte Zertifikate in
`~/runtipi/traefik/shared/acme.json` und erneuert sie weiter, solange der Eintrag dort steht -
unabhängig davon, ob noch ein Router/App existiert. Da das DNS nicht mehr auflöst, schlägt die
Erneuerung täglich mit `NXDOMAIN` fehl.

**Behebung (Runbook):**

```bash
cd ~/runtipi
# 1. Sicherstellen, dass die Apps wirklich deinstalliert sind (keine Container mehr):
docker ps -a | grep -Ei 'neko|chatai|chat|code|bookmarks|cal|heim' || echo "keine Container - gut"

# 2. Reverse Proxy stoppen (acme.json darf nur im Stillstand bearbeitet werden):
docker stop runtipi-reverse-proxy

# 3. Diesen Store auf dem Host auschecken (privates Repo, z. B.):
#    git clone <foxhole-repo-url> /tmp/foxhole

# 4. Betroffene Zertifikate anzeigen (Dry-Run):
/tmp/foxhole/scripts/prune-stale-acme-certs.sh --list

# 5. Entfernen (legt Backup acme.json.bak-<zeitstempel> an, setzt chmod 600):
/tmp/foxhole/scripts/prune-stale-acme-certs.sh --apply

# 6. Proxy wieder starten:
docker start runtipi-reverse-proxy
```

**Hinweise zur Ausführung:**

- `Permission denied` beim Ausführen = fehlendes Executable-Bit (z. B. Datei per Copy/`wget` statt
  `git clone` kopiert) oder `noexec`-Mount: `chmod +x scripts/prune-stale-acme-certs.sh` oder Aufruf
  via `bash scripts/prune-stale-acme-certs.sh ...`.
- Bei `sudo` zeigt `$HOME` auf `/root`. Das Skript erkennt dann automatisch das Home des
  `SUDO_USER`; alternativ explizit: `--acme /home/kai/runtipi/traefik/shared/acme.json`.
- Alle `acme.json`-Kandidaten unter dem runtipi-Root werden gesucht (`find ~/runtipi -maxdepth 5
  -name acme.json -type f`). **Leere oder ungültige Dateien werden mit Hinweis übersprungen** —
  z. B. liegt an `traefik/shared/acme.json` manchmal ein leerer Placeholder, während die echte
  Datei unter `state/traefik/shared/acme.json` liegt (versionsabhängig).
- Ist die gewählte Datei korrupt (kein valides JSON), meldet das Skript Größe + Dateianfang.
  Dann: Backup einspielen (`acme.json.bak-*`) oder Datei löschen und Proxy neu starten
  (Zertifikate werden neu ausgestellt). Wo Traefik wirklich speichert, sieht man an den Mounts:
  `docker inspect runtipi-reverse-proxy --format '{{json .Mounts}}' | jq`.

**Kontrolle (24-48 h später):**

```bash
docker logs runtipi-reverse-proxy --since 24h | grep "renewing ACME" | grep NXDOMAIN || echo "keine NXDOMAIN-Fehler mehr"
```

**Hinweise:**

- Die Zertifikate werden nicht revoked. Bei NXDOMAIN ist das unkritisch (niemand kann die Domain
  mehr auflösen); wer revoken will, kann `traefik-certs-cleaner --revoke` nutzen (Rate-Limit beachten).
- `acme.json` nie bearbeiten, während `runtipi-reverse-proxy` läuft - Traefik überschreibt die Datei
  sonst. Das Skript prüft das und bricht ohne `--force` ab.
- Berechtigung nach dem Editieren: `chmod 600 acme.json` (Traefik-Anforderung) - macht das Skript selbst.

**Prävention:** Vor dem Löschen von DNS-Einträgen oder Deinstallieren einer App die Zertifikate
mit `--list`/`--apply` prunen. Apps über die Runtipi-UI deinstallieren (nicht nur Container löschen).

## 3. Klasse B: `middleware "runtipi@docker" does not exist` (Router `sshwifty-migrated@docker`)

**Ursache:** Runtipi benennt Router als `{app-id}-{store-slug}`. `sshwifty-migrated` ist also die App
`sshwifty` aus einem eigenen Store mit dem Slug `migrated`. Dessen `docker-compose.yml` enthält ein
Label der Form `traefik.http.routers.{{RUNTIPI_APP_ID}}.middlewares=runtipi@docker`. Das Middleware
`runtipi` (ForwardAuth gegen den runtipi-Core-Container, definiert per Label
`traefik.http.middlewares.runtipi.forwardauth.address=...`) existiert in der aktuellen
Runtipi-Version nicht mehr im Docker-Provider - Traefik loggt daher bei jedem Request `ERR` und
der Router antwortet nicht.

**Behebung:**

```bash
# 1. Betroffene Container finden:
/tmp/foxhole/scripts/find-stale-traefik-routers.sh
# -> STALE: container=app-sshwifty-migrated-1 router=sshwifty-migrated@docker -> middleware runtipi@docker ...

# 2. Labels des Containers ansehen:
docker inspect app-sshwifty-migrated-1 --format '{{json .Config.Labels}}' | jq

# 3a. App wird noch gebraucht: im Store "migrated" die App-Compose anpassen -
#     das middlewares-Label entfernen oder auf ein weiterhin definiertes Middleware umbiegen,
#     dann die App in Runtipi neu starten (damit docker-compose.generated.yml neu erzeugt wird).
# 3b. App wird nicht mehr gebraucht: in Runtipi deinstallieren (Stop/Remove), ggf. Rest-Container:
#     docker ps -a | grep sshwifty
```

**Kontrolle:**

```bash
docker logs runtipi-reverse-proxy --since 24h | grep "does not exist" || echo "keine Middleware-Fehler mehr"
```

## 4. Klasse C: `Cannot retrieve the ACME challenge for ... (token "makeasmtp.php")`

**Ursache:** Internet-Scanner (Bots) rufen wahllos `/.well-known/acme-challenge/<name>.php` auf
(z. B. `makeasmtp.php`, `mariju.php`, `about.php` auf `cloud.yumachi.de`, `ssh.cloud.yumachi.de`,
`desk.cloud.yumachi.de`, `office.cloud.yumachi.de`, `tpnas.diskstation.me`). Traefik findet zu dem
Token keine laufende Challenge und loggt `ERR`. Das sind keine eigenen Zertifikatsanforderungen
und kein Angriff auf die Zertifikate.

**Maßnahme:** keine. Optional kann man das Log-Spam reduzieren (Rate-Limit am Entrypoint oder
Log-Level), das ist kosmetisch.

## 5. Klasse D: `runtipi-queue` (RabbitMQ)

Der Boot nach `unclean shutdown` ist normal. `dropped 0/0/0 persistent messages and 0 transient
messages` bedeutet: keine Nachrichten verloren. `Time to start RabbitMQ: 143648 ms` ist auf
langsamer Hardware (z. B. NAS) üblich. Keine Maßnahme.

## 6. Kompaktes Runbook (alles auf dem Runtipi-Host)

```bash
cd ~/runtipi
docker stop runtipi-reverse-proxy
/tmp/foxhole/scripts/prune-stale-acme-certs.sh --list
/tmp/foxhole/scripts/prune-stale-acme-certs.sh --apply
docker start runtipi-reverse-proxy
/tmp/foxhole/scripts/find-stale-traefik-routers.sh   # sshwifty-migrated klären (3a/3b)
# 24-48 h später:
docker logs runtipi-reverse-proxy --since 48h | grep -E "renewing ACME.*NXDOMAIN|does not exist" || echo CLEAN
```

## 7. Offene Fragen

- Soll `sshwifty` (Store `migrated`) weiter betrieben werden? Falls ja: Label in der App-Compose
  fixen (3a). Falls nein: deinstallieren (3b).
- Sind die sieben Domains (`neko`, `chatai`, `chat`, `code`, `bookmarks`, `cal`, `heim` `.cloud.yumachi.de`)
  endgültig weg? Dann bleiben die Zertifikate dauerhaft entfernt (Klasse A erledigt).

## 8. Änderungsumfang dieses PRs

- Nur Doku + zwei Host-Skripte (bash + `jq`, beides auf dem Runtipi-Host vorhanden).
- **Keine neuen Abhängigkeiten, kein Image-Wechsel** → SBOM und Security-Scan-Bericht ändern sich nicht.
- Apps im Store unverändert; `bun test` läuft in CI weiter grün.
