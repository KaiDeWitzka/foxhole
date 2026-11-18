# LanguageTool – selbst gehostete Rechtschreib- und Grammatikpruefung

**LanguageTool** ist eine Open-Source-Alternative zu Grammarly: eine lokal betriebene Engine zur
Rechtschreib-, Grammatik- und Stilpruefung in **mehr als 20 Sprachen** (u. a. Deutsch und Englisch).

## Web-Oberflaeche

Auf dem App-Port (z. B. `http://<host>:8214`) laeuft eine **Web-Oberflaeche** (nginx, aehnlich
languagetool.org):

- Text eingeben (oder einfuegen), Sprache waehlen (oder „Automatisch erkennen"), **„Text pruefen“**
- Gefundene Fehler werden **im Text rot unterstrichen**; Klick auf einen Fehler zeigt die
  Erklaerung und Korrektur-Vorschlaege – per Klick wird die Korrektur uebernommen
- Optional: **Picky-Modus** (level=picky) fuer zusaetzliche Stil-Hinweise
- Strg+Enter prueft direkt aus dem Textfeld

## HTTP-API

Ueber **denselben Port** ist die LanguageTool-API erreichbar (nginx proxied `/v2/` an den Server):

```sh
curl --data "language=de&text=Das ist ein Testt." http://<host>:8214/v2/check
```

Nuetzliche Endpunkte: `GET /v2/languages` (verfuegbare Sprachen), `POST /v2/check` (Pruefung).
Damit kann die App z. B. von Browser-Add-ons, WikiJS oder anderen Apps angesprochen werden.

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
- **In-Place-Update:** UI (`web/index.html`) und nginx-Konfiguration werden direkt aus dem
  App-Repo gemountet – Aenderungen greifen nach einem App-Update sofort, auch bei bestehender
  Installation (Runtipi kopiert `data/` nur bei der Erstinstallation).
- Der LT-Server laeuft im Image im „public mode“ (`--public`, `--allow-origin *`): jeder, der den
  App-Port erreicht, kann die API nutzen.
