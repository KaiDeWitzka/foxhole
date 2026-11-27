# fox_datalyze

Internes Werkzeug zur Publikation von Organigrammen aus JSON- oder TTL(RDF)-Exporten.

- **Interaktive SVG-Karte** (barrierefrei, WCAG 2.1 AA): 4 Layouts (Baum, Indented Tree, Sunburst,
  Treemap), Zoom/Pan per Maus und Tastatur, Klick-Details pro Einheit (Rollen, Stellvertretung,
  N.N., Adresse/Kontakt), Volltextsuche mit Highlight
- **PDF / PDF/A / PDF/UA-1**: Druck inkl. Poster-Formate (z. B. A0), Langzeitarchivierung mit
  XMP-Metadaten; Bericht als HTML/PDF
- **Berichte & Auswertungen**: Konsistenz-Check (Referat ohne Leitung, doppelte Leitungsrollen,
  N.N., fehlende Elterndaten), Kennzahlen (pro Ebene, Vakanzquote, Tiefe/Breite …), CSV/XLSX-Export
- **Versions-Diff** zweier Stände (neu/entfernt/verschoben/Rollenwechsel) als Bericht + markierte Karte
- **Pseudonymisierung** als wiederverwendbarer Schritt (deterministische Pseudonyme)
- **REST-API** hinter Session-Login (default an) für Intranet/Ticketsysteme

Läuft als unprivilegierter Container (UID 10001, read-only, keine Capabilities), vollständig offline.
Open Source (MIT): https://github.com/KaiDeWitzka/fox_datalyze

## Hinweise

- Beim ersten Start ohne gesetztes Passwort liegt das Startpasswort in
  `${APP_DATA_DIR}/data/initial-admin-password.txt` (Rechte 0600). Danach `DATALYZE_AUTH_PASS`
  setzen und die Datei löschen.
- Uploads werden nach `DATALYZE_RETENTION_DAYS` (Default 90, 0 = nie) automatisch gelöscht.
- Originaldaten (nicht pseudonymisiert) nie in Issues/PRs anhängen.
