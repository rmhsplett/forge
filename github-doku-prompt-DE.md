# Prompt für Claude: GitHub-Projekt mit ADRs und To-do-Tracking aufsetzen

> Kopiere den gesamten Text unterhalb der Linie in Claude.

---

Ich möchte mein Projekt auf GitHub sauber dokumentieren und organisieren. Bitte hilf mir **Schritt für Schritt** und erkläre mir jeden Schritt in einfacher Sprache – ich bin kein erfahrener Entwickler. Ich arbeite auf **Windows** und nutze PowerShell, VS Code und/oder GitHub Desktop. Bitte gib mir immer die passenden Befehle und Klick-Wege für Windows (keine Mac-/Terminal-Befehle).

## Ziel

Ich will zwei Dinge sauber aufsetzen:
1. **Architecture Decision Records (ADRs)** – kurze Markdown-Dateien, die jede wichtige technische oder konzeptionelle Entscheidung festhalten, damit später nachvollziehbar ist, *warum* etwas so gebaut wurde.
2. **Ein To-do-/Projekt-Tracking**, um Aufgaben und Meilensteine zu verfolgen.

## Teil 1 – ADR-Struktur

Lege im Repository einen Ordner `docs/decisions/` an. Regeln dafür:

- Jede Entscheidung ist eine eigene Datei nach dem Schema `NNNN-kurz-titel.md` – vierstellige, **fortlaufende** Nummer plus Kebab-Case-Titel, z. B. `0001-datenbank-wahl.md`.
- Nummern werden **nie** neu vergeben und Dateien **nie** gelöscht.
- Wird eine Entscheidung später revidiert, lege eine **neue** ADR an, die auf die alte verweist, und setze bei der alten den Status auf „Superseded by ADR NNNN".

Nutze für jede ADR genau diese Vorlage:

```
# ADR NNNN: [Titel der Entscheidung]

**Date:** JJJJ-MM-TT
**Status:** Accepted

## Context
[Warum steht diese Entscheidung an? Welches Problem wird gelöst?]

## Decision
[Was wurde entschieden?]

## Alternatives considered
- **Option A:** [Beschreibung + warum gewählt oder verworfen]
- **Option B:** ...

## Consequences
[Was folgt daraus – positive wie negative Konsequenzen?]

## Related
- ADR NNNN (verwandte Entscheidung)
```

Erlaubte Status:
- **Proposed** – in Diskussion
- **Accepted** – beschlossen und in Kraft
- **Superseded** – durch eine spätere ADR ersetzt
- **Deprecated** – nicht mehr relevant, aber als Historie behalten

Lege außerdem eine `docs/decisions/README.md` an, die als Index dient und das Namensschema, die Vorlage und die Status kurz erklärt.

## Teil 2 – To-do-/Projekt-Tracking

Erkläre mir beide Varianten und empfiehl mir, was für ein kleines Solo-Projekt am sinnvollsten ist:

**Variante A – GitHub Projects (Kanban-Board):**
Zeig mir, wie ich im Repository über den Reiter „Projects" ein Board mit den Spalten *To do / In progress / Done* anlege, Aufgaben als Items bzw. Issues hinzufüge und optional mit Meilensteinen (Milestones) verknüpfe.

**Variante B – Markdown-Roadmap (leichtgewichtig):**
Lege eine Datei `docs/ROADMAP.md` an, in der Meilensteine und Aufgaben als Checklisten stehen, z. B.:

```
# Roadmap

## Meilenstein 1 – [Name]
- [x] Erledigte Aufgabe
- [ ] Offene Aufgabe

## Meilenstein 2 – [Name]
- [ ] ...
```

## Teil 3 – README und Grundstruktur

Erstelle bzw. aktualisiere die `README.md` im Hauptverzeichnis mit: Projektname, kurze Beschreibung, Übersicht der Ordnerstruktur, sowie Verweisen auf `docs/decisions/` und `docs/ROADMAP.md`.

## Teil 4 – Git/GitHub auf Windows

Führe mich durch die folgenden Punkte und zeig mir jeweils **beide** Wege – den grafischen mit **GitHub Desktop** (einfacher für Einsteiger) und den über die **PowerShell**:
- Ein Repository auf github.com anlegen und lokal klonen.
- Änderungen speichern und hochladen: in PowerShell mit `git add .`, `git commit -m "kurze Nachricht"`, `git push`; in GitHub Desktop über „Commit" + „Push".
- Sinnvolle, kurze Commit-Nachrichten (Konvention erklären).
- Optional: **GitHub Pages** aktivieren, falls ich später eine kleine Doku- oder Projektseite hosten möchte – erklär mir die Einstellung unter *Settings → Pages* (Branch + Ordner auswählen).

## Wie du mit mir arbeiten sollst

- Stell mir zuerst **2–3 kurze Rückfragen** zu meinem Projekt (Worum geht es? Welche Technik/Programmiersprache? Arbeite ich allein?), **bevor** du Dateien anlegst.
- Erkläre jeden Schritt einfach und gib mir konkrete Windows-Befehle bzw. Klick-Wege.
- Lege die Dateien mit sinnvollem Beispiel-Inhalt an, den ich anpassen kann – inklusive einer ersten Beispiel-ADR (`0001-...`).
- Halte die Struktur schlank und pflegeleicht, damit ich sie als Nicht-Profi dauerhaft aktuell halten kann.

Fang bitte damit an, mir die Rückfragen zu meinem Projekt zu stellen.
