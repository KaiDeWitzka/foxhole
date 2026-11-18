# LanguageTool – selbst gehostete Rechtschreib- und Grammatikpruefung

**LanguageTool** ist eine Open-Source-Alternative zu Grammarly: eine lokal betriebene Engine zur
Rechtschreib-, Grammatik- und Stilpruefung in **mehr als 20 Sprachen** (u. a. Deutsch und Englisch).

Diese App stellt den LanguageTool-**HTTP-Server** bereit (Image `erikvl87/languagetool`, intern Port
**8010**, oeffentlich mit `--allow-origin *`). darueber kann die Pruefung per API genutzt werden, z. B.:

```sh
curl --data "language=de&text=Das ist ein Testt." http://<host>:8214/v2/check
```

Nuetzliche Endpunkte: `GET /v2/languages` (verfuegbare Sprachen), `POST /v2/check` (Pruefung).

## Hinweise

- Der Server laeuft vollstaendig lokal – keine Texte verlassen das Heimnetz (im Gegensatz zur
  oeffentlichen API auf languagetool.org).
- **Java-Heap** ist in den App-Einstellungen von Runtipi konfigurierbar (`Java_Xms`/`Java_Xmx`,
  Standard dieser App: 512m/2g). Mehr RAM verbessert die Pruefung langer Texte.
- Weitere LanguageTool-Server-Optionen lassen sich grundsaetzlich ueber Umgebungsvariablen mit dem
  Prefix `langtool_` setzen (z. B. `langtool_pipelinePrewarming=true`), siehe
  [Image-Dokumentation](https://github.com/Erikvl87/docker-languagetool).
- Das Image enthaelt bereits das FastText-Sprachmodell; es werden keine Daten zur Laufzeit
  heruntergeladen und kein persistentes Volume benoetigt.
