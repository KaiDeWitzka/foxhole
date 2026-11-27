# Example App Store Template

This repository serves as a template for creating your own custom app store for the Runtipi platform. Use this as a starting point to create and share your own collection of applications.

## Repository Structure

- **apps/**: Contains individual app directories

  - Each app has its own folder (e.g., `whoami/`) with the following structure:
    - `config.json`: App configuration file
    - `docker-compose.json`: Docker setup for the app
    - `metadata/`: Contains app visuals and descriptions
      - `description.md`: Markdown description of the app
      - `logo.jpg`: App logo image

- **tests/**: Contains test files for the app store

  - `apps.test.ts`: Test suite for validating apps

## Getting Started

This repository is intended to serve as a template for creating your own app store. Follow these steps to get started:

1. Click the "Use this template" button to create a new repository based on this template
2. Customize the apps or add your own app folders in the `apps/` directory
3. Test your app store by using it with Runtipi

## Documentation

For detailed instructions on creating your own app store, please refer to the official guide:
[Create Your Own App Store Guide](https://runtipi.io/docs/guides/create-your-own-app-store)

## Apps in this store

| App | Description |
|---|---|
| fox_netmap | Interaktive Netzwerkkarte des Heimnetzes |
| fox_datalyze | Organigramme aus JSON/TTL publizieren: interaktive SVG-Karte, PDF/PDF-A, Berichte, Diff, Pseudonymisierung |
| languagetool, whoami, filezilla, jlesage-firefox, psitransfer | diverse |

## Betrieb & Troubleshooting (Runtipi-Host)

- [Fehleranalyse runtipi-Logs 2026-11](docs/runtipi-betrieb/logfehler-2026-11.md) — stale ACME-Zertifikate (NXDOMAIN), `middleware "runtipi@docker" does not exist` (sshwifty-migrated), ACME-Scan-Token (harmlos)
- Host-Skripte:
  - `scripts/prune-stale-acme-certs.sh` — stale Zertifikate sicher aus `acme.json` entfernen (Dry-Run default, Backup, `chmod 600`, Guard gegen laufendem `runtipi-reverse-proxy`)
  - `scripts/find-stale-traefik-routers.sh` — Container mit Routern auf nicht existierende `@docker`-Middlewares finden

