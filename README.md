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
| **fox_data2orga** (`apps/fox_data2orga/`) | Organigramme aus JSON/TTL/LDAP erzeugen: SVG, PDF, PDF/A-3b, interaktive Karte, REST-API v1, Web-UI mit History – alles lokal, barrierefrei (WCAG 2.1 AA). Projekt: https://github.com/KaiDeWitzka/fox_data2orga |
| fox_netmap | Interaktive Netzwerkkarte des Heimnetzes |
| languagetool, whoami, filezilla, jlesage-firefox, psitransfer | diverse |

Hinweis fox_data2orga: Image `ghcr.io/kaidewitzka/fox_data2orga:main` wird mit der
Public-Schaltung des Projekt-Repos veröffentlicht. Bis dahin lokal bauen und taggen
(`docker build -t ghcr.io/kaidewitzka/fox_data2orga:main .` im Projekt-Repo) und in
Runtipi unter „Einstellungen → App anpassen" (user-config) das Image setzen.
