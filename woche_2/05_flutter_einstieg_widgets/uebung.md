# Modul 5: Uebung -- Visitenkarten-App

## Aufgabenstellung

Erstelle eine **digitale Visitenkarten-App**, die deine (oder eine fiktive) Kontaktinformation anzeigt. Die App soll professionell aussehen und die grundlegenden Flutter-Widgets demonstrieren.

---

## Anforderungen

### 1. Projektsetup

- Erstelle ein neues Flutter-Projekt mit `flutter create visitenkarte`
- Verwende `MaterialApp` mit einem benutzerdefinierten Theme (`ThemeData` mit `ColorScheme.fromSeed`)
- Entferne das Debug-Banner (`debugShowCheckedModeBanner: false`)

### 2. Profilbild (oben, zentriert)

- Verwende `CircleAvatar` fuer ein rundes Profilbild
- Radius: mindestens 60
- Verwende entweder ein Netzwerk-Bild (`NetworkImage`) oder einen Initialen-Text als Fallback
- Das Profilbild soll zentriert ueber dem Namen stehen

### 3. Name und Berufsbezeichnung

- Der vollstaendige Name in grosser, fetter Schrift
- Die Berufsbezeichnung darunter, etwas kleiner und in grauer Farbe
- Verwende passende `TextStyle`-Eigenschaften
- Ein `Divider` (Trennlinie) unterhalb der Berufsbezeichnung

### 4. Kontaktinformationen

Zeige mindestens drei Kontaktinformationen an, jeweils mit:
- Einem passenden Icon (z.B. `Icons.phone`, `Icons.email`, `Icons.location_on`, `Icons.web`)
- Dem Kontakttext daneben
- Verwende `Card` oder `ListTile` fuer jede Kontaktinformation
- Die Kontaktzeilen sollen einheitlich gestaltet sein

Beispiel-Kontaktdaten:
- Telefon: +49 123 456 7890
- E-Mail: max.mustermann@example.de
- Standort: Berlin, Deutschland
- Webseite: www.example.de

### 5. Widget-Extraktion (wichtig!)

Erstelle **mindestens drei eigene StatelessWidgets**:

1. `VisitenkartApp` -- Das Root-Widget mit MaterialApp
2. `VisitenkartSeite` -- Die Hauptseite mit Scaffold
3. `KontaktZeile` -- Ein wiederverwendbares Widget fuer eine einzelne Kontaktinformation (mit `icon` und `text` als Parameter)

Optional weitere:
- `ProfilHeader` -- Der obere Bereich mit Bild, Name und Beruf
- `KontaktBereich` -- Der Bereich mit allen Kontaktzeilen

### 6. Styling und Design

- Verwende ein konsistentes Farbschema ueber `ThemeData`
- Nutze `Padding` und `SizedBox` fuer Abstaende
- Die Seite soll vertikal zentriert sein (oder mit angenehmen Abstaenden)
- Hintergrundfarbe der Seite darf vom Standard abweichen
- Verwende mindestens eine `Card` mit Schatten (`elevation`)

---

## Bonus-Aufgaben (optional)

1. **Dark Theme:** Implementiere ein dunkles Theme (`ThemeData.dark()` als Basis)
2. **Social Media Icons:** Fuege eine Reihe von Social-Media-Icons hinzu (als `Row` mit `IconButton`s)
3. **Gradient-Hintergrund:** Verwende einen Farbverlauf als Hintergrund im oberen Bereich
4. **Responsive:** Nutze `MediaQuery`, um die Schriftgroesse auf kleinen Bildschirmen anzupassen

---

## Hinweise

- Starte die App regelmaessig mit `flutter run` und nutze Hot Reload (`r` im Terminal oder Strg+S), um deine Aenderungen sofort zu sehen.
- Denke daran, `const` zu verwenden, wo es moeglich ist.
- Teste verschiedene `MainAxisAlignment`-Optionen in deiner `Column`.
- Wenn du ein Netzwerk-Bild verwendest, stelle sicher, dass eine Internet-Verbindung besteht.

---

## Erwartetes Ergebnis

Die App soll ungefaehr so aufgebaut sein:

```
┌─────────────────────────────┐
│         [AppBar]            │
│      Meine Visitenkarte     │
├─────────────────────────────┤
│                             │
│         ┌──────┐            │
│         │ Foto │            │
│         └──────┘            │
│                             │
│      Max Mustermann         │
│    Flutter-Entwickler       │
│    ─────────────────        │
│                             │
│  ┌─────────────────────┐    │
│  │ 📞 +49 123 456 789  │    │
│  └─────────────────────┘    │
│  ┌─────────────────────┐    │
│  │ ✉  max@example.de   │    │
│  └─────────────────────┘    │
│  ┌─────────────────────┐    │
│  │ 📍 Berlin, DE       │    │
│  └─────────────────────┘    │
│  ┌─────────────────────┐    │
│  │ 🌐 www.example.de   │    │
│  └─────────────────────┘    │
│                             │
└─────────────────────────────┘
```
