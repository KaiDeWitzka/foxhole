#!/usr/bin/env bash
# find-stale-traefik-routers.sh - findet Docker-Container, deren Traefik-Router auf
# @docker-Middlewares verweisen, die kein Container mehr definiert.
#
# Symptom in den runtipi-reverse-proxy-Logs:
#   error="middleware \"runtipi@docker\" does not exist" entryPointName=websecure routerName=sshwifty-migrated@docker
#
# Middlewares zaehlen global: ein Label auf irgendeinem Container (z. B. dem
# runtipi-Core-Container) definiert das Middleware fuer alle Router.
#
# Exit-Code: 0 = alles OK, 1 = mindestens eine stale Referenz gefunden (oder Docker fehlt).
set -euo pipefail

if ! command -v docker >/dev/null 2>&1; then
  echo "FEHLER: docker fehlt" >&2
  exit 1
fi
if ! docker info >/dev/null 2>&1; then
  echo "FEHLER: Docker-Daemon nicht erreichbar" >&2
  exit 1
fi

mapfile -t CONTAINERS < <(docker ps -a --format '{{.Names}}')

labels_of() {
  docker inspect -f '{{json .Config.Labels}}' "$1" 2>/dev/null || echo 'null'
}

declare -A DEFINED=()
for c in "${CONTAINERS[@]}"; do
  labels="$(labels_of "$c")"
  if [[ -z "$labels" || "$labels" == "null" ]]; then
    continue
  fi
  while IFS= read -r mw; do
    [[ -n "$mw" ]] && DEFINED["$mw"]=1
  done < <(jq -r 'keys[]? | select(startswith("traefik.http.middlewares.")) | sub("^traefik\\.http\\.middlewares\\."; "") | split(".")[0]' <<<"$labels")
done

STALE=0
for c in "${CONTAINERS[@]}"; do
  labels="$(labels_of "$c")"
  if [[ -z "$labels" || "$labels" == "null" ]]; then
    continue
  fi

  refs="$(jq -r 'to_entries[]
    | select(.key | test("^traefik\\.http\\.routers\\.[^.]+\\.middlewares$"))
    | (.key | sub("^traefik\\.http\\.routers\\."; "") | split(".")[0]) as $router
    | (.value | split(",")[] | select(endswith("@docker")) | sub("@docker$"; ""))
    | "\($router)\t\(.)"' <<<"$labels")"

  if [[ -z "$refs" ]]; then
    continue
  fi

  while IFS=$'\t' read -r router mw; do
    if [[ -z "${DEFINED[$mw]:-}" ]]; then
      echo "STALE: container=$c router=${router}@docker -> middleware ${mw}@docker wird von keinem Container definiert"
      STALE=1
    fi
  done <<<"$refs"
done

if [[ $STALE -eq 0 ]]; then
  echo "OK: alle @docker-Middleware-Referenzen sind definiert."
else
  echo
  echo "Behebung: Labels des betroffenen Containers ansehen:"
  echo "  docker inspect <container> --format '{{json .Config.Labels}}' | jq"
  echo "Dann App-Compose im Store anpassen (middlewares-Label entfernen/korrigieren) oder App deinstallieren."
  echo "siehe docs/runtipi-betrieb/logfehler-2026-11.md"
fi
exit "$STALE"
