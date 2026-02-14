# Modul 13: Animationen -- Übung

## Animierte Produktkarten-App

Erstelle eine App, die verschiedene Animationstypen kombiniert, um ein ansprechendes Shopping-Erlebnis zu schaffen.

---

### Projektsetup

```bash
flutter create animierte_produkte
cd animierte_produkte
```

Füge folgende Dependency zu `pubspec.yaml` hinzu:

```yaml
dependencies:
  lottie: ^3.1.0
```

Lade eine Lottie-Animation (z.B. eine Ladeanimation) von https://lottiefiles.com herunter und speichere sie als `assets/animations/loading.json`. Registriere den Assets-Ordner in `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/animations/
```

---

### Aufgabe 1: Produktliste mit AnimatedList

Erstelle eine Produktliste, bei der Items beim Hinzufügen von rechts hereinrutschen und beim Entfernen nach links herausrutschen.

**Anforderungen:**
- Erstelle ein `Produkt`-Modell mit: `id`, `name`, `preis`, `istNeu` (bool), `istLiked` (bool)
- Verwende `AnimatedList` statt `ListView`
- Beim Hinzufügen: Das Item soll von rechts hereinrutschen (SlideTransition + FadeTransition)
- Beim Entfernen: Das Item soll nach links herausrutschen und gleichzeitig ausblenden
- Füge einen FloatingActionButton hinzu, der ein neues zufälliges Produkt hinzufügt
- Swipe-to-Delete mittels `Dismissible` innerhalb der AnimatedList

**Hinweise:**
- Verwende `GlobalKey<AnimatedListState>` um auf die AnimatedList zuzugreifen
- `insertItem()` und `removeItem()` sind die Schlüsselmethoden
- Kombiniere `SlideTransition` und `FadeTransition` für den Effekt

---

### Aufgabe 2: Produktkarte mit Expand/Collapse

Jede Produktkarte soll bei Antippen expandieren und zusätzliche Details anzeigen.

**Anforderungen:**
- Verwende `AnimatedContainer` für die Höhenänderung der Karte
- Im eingeklappten Zustand: Name und Preis anzeigen
- Im ausgeklappten Zustand: Zusätzlich Beschreibung, Bewertung und "In den Warenkorb"-Button
- Die Beschreibung soll mit `AnimatedOpacity` ein-/ausgeblendet werden
- Verwende `AnimatedCrossFade` für den Wechsel des Expand/Collapse-Icons (Pfeil nach unten/oben)
- Die Höhenanimation soll die Kurve `Curves.easeInOut` mit 400ms verwenden

**Hinweise:**
- Verwalte den `_istErweitert`-Zustand pro Karte (nicht global)
- Verwende `AnimatedContainer` mit einer `height`-Eigenschaft oder `AnimatedSize`

---

### Aufgabe 3: Hero-Animation zur Detailseite

Tippe auf das Produktbild, um zur Detailseite zu navigieren -- mit einer fließenden Hero-Animation.

**Anforderungen:**
- Jede Produktkarte hat ein Platzhalterbild (verwende `Container` mit Farbe oder `Icon`)
- Umgib das Bild mit einem `Hero`-Widget mit einem eindeutigen `tag` pro Produkt
- Erstelle einen `ProduktDetailScreen`, der das gleiche `Hero`-Widget enthält
- Das Bild soll auf der Detailseite groß und oben angezeigt werden
- Unter dem Bild: Produktname, Preis, Beschreibung
- Der Zurück-Button soll die Hero-Animation rückwärts abspielen

**Hinweise:**
- Der Hero-`tag` muss auf beiden Screens identisch sein
- Verwende `Navigator.push()` für die Navigation

---

### Aufgabe 4: Pulsierende "Neu"-Badge

Produkte mit `istNeu == true` sollen ein animiertes Badge haben, das pulsiert.

**Anforderungen:**
- Erstelle ein `NeuBadge`-Widget als `StatefulWidget` mit `SingleTickerProviderStateMixin`
- Verwende einen `AnimationController` mit `repeat(reverse: true)` für den Pulseffekt
- Die Badge-Größe soll zwischen Faktor 0.9 und 1.1 pulsieren (ScaleTransition oder Transform.scale)
- Die Opacity soll leicht zwischen 0.7 und 1.0 schwanken
- Verwende `Curves.easeInOut` für eine sanfte Pulsierung
- Die Pulsier-Dauer soll 1 Sekunde betragen
- Positioniere das Badge mit `Positioned` oben rechts auf der Karte

**Hinweise:**
- Denke an `dispose()` für den AnimationController
- Verwende `AnimatedBuilder` für die Darstellung

---

### Aufgabe 5: Like-Button mit AnimatedSwitcher

Der Like-Button soll beim Antippen eine Animation abspielen, die zwischen dem leeren und gefüllten Herz-Icon wechselt.

**Anforderungen:**
- Ungeklickt: `Icons.favorite_border` in Grau
- Geklickt: `Icons.favorite` in Rot
- Verwende `AnimatedSwitcher` für den Icon-Wechsel
- Die Transition soll eine Kombination aus Scale und Rotation sein (benutzerdefinierter `transitionBuilder`)
- Dauer: 300ms
- Beim Liken soll das Icon kurz größer werden und dann auf Normalgröße zurückfedern

**Hinweise:**
- Gib jedem Icon einen unterschiedlichen `ValueKey`, damit der `AnimatedSwitcher` den Wechsel erkennt
- Du kannst im `transitionBuilder` mehrere Transitions verschachteln

---

### Aufgabe 6: Lottie-Animation als Ladeindikator

Zeige beim Start der App eine Lottie-Animation als Ladebildschirm.

**Anforderungen:**
- Zeige beim App-Start für 3 Sekunden einen Ladebildschirm mit einer Lottie-Animation
- Verwende `Lottie.asset()` mit einer heruntergeladenen Animation
- Nach dem Laden: Übergang zur Produktliste mit einem Fade-Effekt
- Der Übergang soll über `AnimatedSwitcher` oder manuell über `AnimatedOpacity` gesteuert werden
- Optional: Steuere die Lottie-Animation über einen eigenen `AnimationController`

**Hinweise:**
- Verwende `Future.delayed()` oder `Timer` um den Ladevorgang zu simulieren
- Alternativ kannst du auch `Lottie.network()` verwenden, wenn du keine lokale Datei nutzen möchtest

---

### Bonus: Warenkorb-Fly-Animation

Wenn der "In den Warenkorb"-Button gedrückt wird, soll das Produktbild zum Warenkorb-Icon in der AppBar fliegen.

**Anforderungen:**
- Ermittle die Position des Produktbilds und des Warenkorb-Icons mit `GlobalKey` und `RenderBox`
- Verwende ein `Overlay` und `AnimatedPositioned` (oder explizite Animation mit `AnimationController`) um das Bild zu animieren
- Das Bild soll gleichzeitig schrumpfen und zum Ziel fliegen
- Am Ende soll der Warenkorb-Zähler hochzählen (AnimatedSwitcher)

---

### Abgabekriterien

- [ ] AnimatedList mit Ein-/Ausblendeeffekt beim Hinzufügen/Entfernen
- [ ] Expand/Collapse-Animation der Produktkarten
- [ ] Hero-Animation zum Detailscreen
- [ ] Pulsierendes "Neu"-Badge mit expliziter Animation
- [ ] Like-Button mit AnimatedSwitcher-Transition
- [ ] Lottie-Ladebildschirm
- [ ] Sauberer Code mit Kommentaren
- [ ] Alle AnimationController werden in `dispose()` aufgeräumt
