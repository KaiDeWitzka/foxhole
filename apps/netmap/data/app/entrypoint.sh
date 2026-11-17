#!/bin/sh
# Netzwerkkarte-Scanner: scannt zyklisch das LAN und schreibt die Karte nach /data/web
# (kein TLS-Zertifikat mehr noetig: der Web-Container spricht plain HTTP auf internal_port,
#  HTTPS terminiert am Edge - Runtipi local SSL / NPM)
set -u
OUT=/data/web
mkdir -p "$OUT"
INTERVAL="${NETZ_SCAN_INTERVAL:-900}"
SUBNET_ARG=""
if [ -n "${NETZ_SUBNET:-}" ]; then
  SUBNET_ARG="--subnet ${NETZ_SUBNET}"
fi
# In-Place-Update: frische Skripte aus dem installierten App-Ordner uebernehmen.
# Runtipi kopiert data/ nur bei der Erstinstallation nach app-data - /runtipi-apps
# ist das apps/-Verzeichnis der Runtipi-Installation (Mount siehe docker-compose.yml).
# entrypoint.sh selbst wird NICHT ueberschrieben (sh liest das Skript zur Laufzeit).
if [ -n "${APP_DATA_DIR:-}" ] && [ -d /runtipi-apps ]; then
  STORE=$(basename "$(dirname "$APP_DATA_DIR")")
  APPNAME=$(basename "$APP_DATA_DIR")
  FRESH="/runtipi-apps/$STORE/$APPNAME/app"
  if [ -f "$FRESH/netzwerkkarte.py" ]; then
    for f in netzwerkkarte.py serve_https.py; do
      if [ -f "$FRESH/$f" ] && ! cmp -s "$FRESH/$f" "/opt/netzwerkkarte/$f" 2>/dev/null; then
        cp "$FRESH/$f" "/opt/netzwerkkarte/$f" && echo "In-Place-Update: $f aktualisiert"
      fi
    done
  fi
fi
echo "Starte Netzwerkkarte-Scanner (Intervall: ${INTERVAL}s, Subnetz: ${NETZ_SUBNET:-auto})"
while true; do
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Scanne Netzwerk ..."
  # shellcheck disable=SC2086
  python3 /opt/netzwerkkarte/netzwerkkarte.py ${SUBNET_ARG} --out-dir "$OUT" || echo "Scan fehlgeschlagen - naechster Versuch in ${INTERVAL}s"
  sleep "$INTERVAL"
done
