# fox_data2orga

Erzeugt aus Organigramm-Daten im **JSON- oder TTL(RDF)-Format** (optional direkt aus **LDAP/AD**) alle Publikationsformate:

- **SVG** (barrierefrei, Web-Einbettung), **PDF** (Druck), **PDF/A-3b** (Langzeitarchivierung)
- **barrierefreie HTML-Textliste** und **zoombare interaktive Karte** (cytoscape, Tastaturbedienbar, `prefers-reduced-motion`)
- Layouts: Baum (oben/links), **Sunburst, Treemap, Poster A0, Indented Tree**
- **Version-Vergleich** zweier Stände: Änderungsbericht + farblich markiertes Organigramm/Karte
- **Konsistenz-Report** (Referat ohne Leitung, doppelte Leitungsrollen, „N.N.“, fehlende Elterndaten)
- **Volltextsuche** inkl. Kontakt-/Adressfelder + **Kontakt-/Erreichbarkeitsfinder** mit Stellvertretungs-Ketten
- **Kennzahlen** (Einheiten pro Ebene, Ø Referate pro Abteilung, Vakanzquote, …) als CSV **und XLSX**
- **REST-API v1** (`/api/v1/*`, Bearer-Token, Rate-Limit, OpenAPI unter `/api/v1/docs`) für Intranet/Ticketsysteme
- Web-UI mit Multi-Upload (Drag & Drop), Upload-History (SQLite), Pseudonymisierungs-Schritt

## Datenschutz & Sicherheit

- Alle Daten bleiben **lokal** auf deinem Server (Volume unter `${APP_DATA_DIR}/data`); nichts verlässt die App.
- **Pseudonymisierung** als wiederverwendbarer Schritt (CLI `data2orga pseudonymize`, API, UI) vor jeder Weitergabe.
- Originaldaten gehören nie ins Repo – dafür gibt es einen Denylist-Scan in der CI.
- Gehärtetes Image: non-root (uid 10001), read-only Root-FS, `cap_drop: ALL`, `no-new-privileges`, digest-gepinnte Base, hash-gepinnte Python-Dependencies, Trivy-Gate + SBOM in der CI.
- **Basic-Auth** über die Formularfelder (DATA2ORGA_USER/PASSWORD) – bei Expose über eine Domain oder Zugriff aus dem LAN dringend empfohlen.
- **LDAP/AD-Import** optional: TLS erzwungen (ldaps/STARTTLS), Dienstkonto mit nur Lesezugriff, Passwort nur in der `app.env` des Runtipi-Hosts (nie im Log). Spezifikation: `docs/ldap.md` im Projekt-Repo.

## Hinweise

- Standard-Port: **8000** (Runtipi mappt `${APP_PORT}` automatisch).
- Healthcheck: `/api/health` (ohne Auth).
- API-Token anlegen: `docker exec fox-data2orga python -m data2orga api-token --name intranet`
- Quelle & Doku: https://github.com/KaiDeWitzka/fox_data2orga (aktuell private, Public-Schaltung geplant; Image dann auf GHCR unter `ghcr.io/kaidewitzka/fox_data2orga:main`)
