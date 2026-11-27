#!/usr/bin/env bash
# prune-stale-acme-certs.sh - entfernt stale ACME-Zertifikate aus der Traefik-acme.json einer Runtipi-Instanz.
#
# Hintergrund: Traefik erneuert Zertifikate aus acme.json weiter, auch wenn die DNS-Namen
# laengst nicht mehr existieren (NXDOMAIN). Das fuellt die runtipi-reverse-proxy-Logs mit
# "Error renewing ACME certificate" und verbraucht Let's-Encrypt-Rate-Limits.
#
# WICHTIG: acme.json darf nur bearbeitet werden, wenn Traefik NICHT laeuft -
# sonst ueberschreibt der Proxy die Datei beim naechsten Schreiben. Das Skript prueft
# das und bricht ohne --force ab.
#
# Standard-Domainliste ist der Vorfall 2026-11 (ehemalige App-Domains ohne DNS-Eintrag).
set -euo pipefail

DEFAULT_DOMAINS=(
  "neko.cloud.yumachi.de"
  "chatai.cloud.yumachi.de"
  "chat.cloud.yumachi.de"
  "code.cloud.yumachi.de"
  "bookmarks.cloud.yumachi.de"
  "cal.cloud.yumachi.de"
  "heim.cloud.yumachi.de"
)

usage() {
  cat <<'EOF'
Aufruf: prune-stale-acme-certs.sh [Optionen]

Optionen:
  --acme <pfad>     acme.json explizit angeben (sonst Auto-Detect unter ~/runtipi/...)
  --resolver <name> nur diesen ACME-Resolver bearbeiten, default: * (alle)
  --domain <d>      zusaetzliche Domain (wiederholbar). Match: exakt oder Subdomain.
                    Ohne --domain wird die Vorfall-Liste 2026-11 verwendet.
  --list            nur anzeigen, nichts aendern (immer Dry-Run ohne --apply)
  --apply           Zertifikate wirklich entfernen (Backup wird angelegt, chmod 600)
  --force           auch ausfuehren, wenn runtipi-reverse-proxy gerade laeuft (nicht empfohlen)
  -h, --help        dieser Text

Ablauf empfohlen:
  docker stop runtipi-reverse-proxy
  prune-stale-acme-certs.sh --list
  prune-stale-acme-certs.sh --apply
  docker start runtipi-reverse-proxy
EOF
}

ACME=""
RESOLVER="*"
APPLY=0
FORCE=0
DOMAINS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --acme) ACME="${2:?--acme braucht einen Pfad}"; shift 2 ;;
    --resolver) RESOLVER="${2:?--resolver braucht einen Namen}"; shift 2 ;;
    --domain) DOMAINS+=("${2:?--domain braucht eine Domain}"); shift 2 ;;
    --list) shift ;;
    --apply) APPLY=1; shift ;;
    --force) FORCE=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unbekannte Option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

if [[ ${#DOMAINS[@]} -eq 0 ]]; then
  DOMAINS=("${DEFAULT_DOMAINS[@]}")
fi

command -v jq >/dev/null 2>&1 || { echo "FEHLER: jq fehlt (z. B. apt install jq)" >&2; exit 1; }

if [[ -z "$ACME" ]]; then
  for candidate in \
    "${RUNTIPI_DIR:-/nonexistent}/traefik/shared/acme.json" \
    "$HOME/runtipi/traefik/shared/acme.json" \
    "$HOME/runtipi/state/traefik/acme.json" \
    "$HOME/runtipi/app-data/traefik/shared/acme.json" \
    "./acme.json"; do
    if [[ -f "$candidate" ]]; then ACME="$candidate"; break; fi
  done
fi

if [[ -z "$ACME" || ! -f "$ACME" ]]; then
  echo "FEHLER: acme.json nicht gefunden - bitte --acme <pfad> angeben" >&2
  exit 1
fi

jq -e . "$ACME" >/dev/null 2>&1 || { echo "FEHLER: $ACME ist kein valides JSON" >&2; exit 1; }

if [[ $APPLY -eq 1 && $FORCE -eq 0 ]] && command -v docker >/dev/null 2>&1; then
  if docker ps --format '{{.Names}}' 2>/dev/null | grep -qx "runtipi-reverse-proxy"; then
    echo "FEHLER: runtipi-reverse-proxy laeuft - Traefik wuerde acme.json ueberschreiben." >&2
    echo "Erst stoppen: docker stop runtipi-reverse-proxy   (oder --force um trotzdem zu schreiben)" >&2
    exit 1
  fi
fi

STALE_JSON=$(printf '%s\n' "${DOMAINS[@]}" | jq -R . | jq -s .)

IS_STALE='
  def is_stale($domains):
    ([.domain.sans[]? // empty] + [(.domain.main // "")]) |
    any(. as $h | $domains | any(. as $d | $h == $d or ($h | endswith("." + $d))));
'

echo "acme.json : $ACME"
echo "Resolver  : $RESOLVER"
echo "Domains   : ${DOMAINS[*]}"
echo

STALE=$(jq -r --argjson stale "$STALE_JSON" --arg resolver "$RESOLVER" "$IS_STALE"'
  (if $resolver == "*"
   then to_entries[] | select(.value | type == "object" and has("Certificates")) | {r: .key, c: .value.Certificates[]?}
   else {r: $resolver, c: .[$resolver].Certificates[]?} end)
  as $pair | $pair.c | select(is_stale($stale)) | "\($pair.r)\t\(.domain.main // "?")\t\((.domain.sans // []) | join(","))"' "$ACME")

if [[ -z "$STALE" ]]; then
  echo "Keine passenden Zertifikate gefunden. Nichts zu tun."
  exit 0
fi

echo "Betroffene Zertifikate (Resolver<TAB>Hauptdomain<TAB>SANs):"
printf '%s\n' "$STALE" | sed 's/^/  /'
echo

if [[ $APPLY -eq 0 ]]; then
  echo "Dry-Run. Zum Entfernen: --apply (runtipi-reverse-proxy vorher stoppen)."
  exit 0
fi

BACKUP="${ACME}.bak-$(date +%Y%m%d-%H%M%S)"
cp -p "$ACME" "$BACKUP"

FILTER='
  def is_stale($domains):
    ([.domain.sans[]? // empty] + [(.domain.main // "")]) |
    any(. as $h | $domains | any(. as $d | $h == $d or ($h | endswith("." + $d))));
  if $resolver == "*" then
    reduce (to_entries[] | select(.value | type == "object" and has("Certificates")) | .key) as $r
      (.; .[$r].Certificates = ([.[$r].Certificates[] | select(is_stale($stale) | not)]))
  else
    .[$resolver].Certificates = ([.[$resolver].Certificates[]? | select(is_stale($stale) | not)] // [])
  end
'

TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT
jq --argjson stale "$STALE_JSON" --arg resolver "$RESOLVER" "$FILTER" "$ACME" > "$TMP"
jq -e . "$TMP" >/dev/null 2>&1 || { echo "FEHLER: Ergebnis kein valides JSON, Original bleibt unveraendert" >&2; exit 1; }
mv "$TMP" "$ACME"
chmod 600 "$ACME"

echo "Entfernt. Backup: $BACKUP"
echo "Berechtigung auf 600 gesetzt (Traefik-Anforderung)."
echo "Naechster Schritt: docker start runtipi-reverse-proxy (bzw. ./runtipi-cli start)."
