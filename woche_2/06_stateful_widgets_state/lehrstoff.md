# Modul 6: StatefulWidgets & State Management Grundlagen

## Lernziele

Nach diesem Modul kannst du:

- Den Unterschied zwischen StatelessWidget und StatefulWidget erklaeren
- StatefulWidgets mit der zugehoerigen State-Klasse erstellen
- `setState()` korrekt einsetzen, um das UI zu aktualisieren
- Den vollstaendigen Widget-Lifecycle verstehen und nutzen
- Keys richtig einsetzen (ValueKey, ObjectKey, UniqueKey, GlobalKey)
- State nach oben heben (Lifting State Up)

---

## 1. Warum StatefulWidget?

Im vorherigen Modul hast du `StatelessWidget` kennengelernt -- Widgets ohne eigenen veraenderlichen Zustand. Aber was, wenn sich etwas aendern soll? Ein Zaehler, der hochzaehlt? Ein Toggle, der an/aus schaltet? Ein Textfeld, das Eingaben speichert?

Dafuer brauchst du **StatefulWidgets**.

### Vergleich zu bekannten Frameworks

| Konzept | React | Vue | Flutter |
|---------|-------|-----|---------|
| Ohne State | Functional Component (ohne Hooks) | Template ohne `data()` | StatelessWidget |
| Mit State | `useState` / Class Component | `data()` / `ref()` | StatefulWidget + State |
| State aendern | `setState()` / `setX()` | Direkte Zuweisung | `setState(() { ... })` |
| Lifecycle | `useEffect` / `componentDidMount` | `mounted`, `onUnmounted` | `initState`, `dispose` |

> **React-Vergleich:** Ein `StatefulWidget` in Flutter ist konzeptionell aehnlich wie eine React Class Component mit `this.state` und `this.setState()`. Der Unterschied: In Flutter sind Widget und State in zwei getrennte Klassen aufgeteilt.

---

## 2. StatefulWidget + State<T>

Ein StatefulWidget besteht immer aus **zwei Klassen**:

1. **Das Widget selbst** (immutable) -- beschreibt die Konfiguration
2. **Die State-Klasse** (mutable) -- haelt den veraenderlichen Zustand

```dart
// Klasse 1: Das Widget (immutable, wird bei Aenderungen neu erstellt)
class MeinZaehler extends StatefulWidget {
  const MeinZaehler({super.key, this.startWert = 0});

  final int startWert; // Konfiguration (immutable)

  @override
  State<MeinZaehler> createState() => _MeinZaehlerState();
}

// Klasse 2: Der State (mutable, lebt laenger als das Widget)
class _MeinZaehlerState extends State<MeinZaehler> {
  late int _zaehler; // Veraenderlicher Zustand

  @override
  void initState() {
    super.initState();
    _zaehler = widget.startWert; // Zugriff auf Widget-Properties ueber 'widget'
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Zaehler: $_zaehler',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _zaehler--;
                });
              },
              child: const Icon(Icons.remove),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _zaehler++;
                });
              },
              child: const Icon(Icons.add),
            ),
          ],
        ),
      ],
    );
  }
}
```

### Warum zwei Klassen?

Das Widget (`MeinZaehler`) ist immutable und wird bei jeder Aenderung des Eltern-Widgets neu erstellt. Der State (`_MeinZaehlerState`) ueberlebt diese Neuerstellung -- er wird einmal erstellt und bleibt bestehen, solange das Widget im Baum ist.

```
Eltern-Widget aendert sich
    ↓
MeinZaehler wird neu erstellt (neue Instanz)
    ↓
Flutter erkennt: gleicher Typ + gleicher Key
    ↓
_MeinZaehlerState bleibt BESTEHEN (gleiche Instanz)
    ↓
didUpdateWidget() wird aufgerufen
    ↓
build() wird aufgerufen
```

### Der `widget`-Getter

In der State-Klasse kannst du ueber `widget` auf die Properties des zugehoerigen Widgets zugreifen:

```dart
class MeinWidget extends StatefulWidget {
  const MeinWidget({super.key, required this.titel});
  final String titel;

  @override
  State<MeinWidget> createState() => _MeinWidgetState();
}

class _MeinWidgetState extends State<MeinWidget> {
  @override
  Widget build(BuildContext context) {
    // Zugriff auf Widget-Properties:
    return Text(widget.titel);
  }
}
```

---

## 3. setState() -- wie und wann

`setState()` ist der Mechanismus, um Flutter mitzuteilen, dass sich der State geaendert hat und das Widget neu gezeichnet werden muss.

### Richtige Verwendung

```dart
// RICHTIG: State-Aenderung INNERHALB von setState
setState(() {
  _zaehler++;
  _name = 'Neuer Name';
  _liste.add('Neues Element');
});

// AUCH RICHTIG: Aenderung VOR setState (funktioniert, aber weniger lesbar)
_zaehler++;
setState(() {});

// FALSCH: setState wird nie aufgerufen --> UI aktualisiert sich nicht!
void _erhoehe() {
  _zaehler++; // Wert aendert sich, aber UI zeigt es nicht
}
```

### Wann setState() aufrufen?

| Szenario | setState noetig? |
|----------|-----------------|
| Button-Klick aendert einen Zaehler | Ja |
| Checkbox wird an/ausgeschaltet | Ja |
| Daten von API geladen | Ja (nach dem Laden) |
| Widget bekommt neue Props vom Eltern-Widget | Nein (build wird automatisch aufgerufen) |
| Animation laeuft | Ja (oder AnimationController nutzen) |

### Regeln fuer setState()

1. **Nur in der State-Klasse aufrufen** -- niemals ausserhalb
2. **Nicht in `build()` aufrufen** -- fuehrt zu Endlosschleife
3. **Nicht in `initState()` aufrufen** -- Widget ist noch nicht fertig gebaut
4. **Nur synchronen Code darin** -- kein `await` innerhalb von `setState`
5. **Nicht nach `dispose()` aufrufen** -- State existiert nicht mehr

```dart
// FALSCH: async in setState
setState(() async {   // <-- NICHT MACHEN
  final daten = await ladeDaten();
  _daten = daten;
});

// RICHTIG: await ausserhalb, setState danach
Future<void> _ladeDaten() async {
  final daten = await ladeDaten();
  if (mounted) {   // Pruefen ob Widget noch im Baum ist
    setState(() {
      _daten = daten;
    });
  }
}
```

> **Wichtig:** Die `mounted`-Pruefung ist essentiell bei asynchronem Code. Wenn der Benutzer die Seite verlaesst, waehrend Daten geladen werden, ist das Widget nicht mehr `mounted`, und `setState()` wuerde einen Fehler werfen.

---

## 4. Widget Lifecycle

Jedes StatefulWidget durchlaeuft einen definierten Lebenszyklus. Das Verstaendnis dieses Zyklus ist entscheidend fuer korrekte Ressourcenverwaltung.

### Lifecycle-Diagramm

```
                    ┌──────────────────┐
                    │   createState()  │  Widget wird erstellt
                    └────────┬─────────┘
                             │
                    ┌────────▼─────────┐
                    │   initState()    │  State wird initialisiert
                    │                  │  (einmalig aufgerufen)
                    └────────┬─────────┘
                             │
              ┌──────────────▼──────────────┐
              │  didChangeDependencies()     │  Abhaengigkeiten geaendert
              │  (InheritedWidget geaendert) │  (auch nach initState)
              └──────────────┬──────────────┘
                             │
                    ┌────────▼─────────┐
              ┌────►│    build()       │  UI wird gebaut
              │     │                  │  (kann mehrfach aufgerufen werden)
              │     └────────┬─────────┘
              │              │
              │     ┌────────▼─────────────┐
              │     │ didUpdateWidget()     │  Eltern-Widget hat sich geaendert
              │     │ (altes Widget verfueg)│  (neues Widget, gleicher State)
              │     └────────┬─────────────┘
              │              │
              └──────────────┘   ← build() wird erneut aufgerufen
                             │
                    ┌────────▼─────────┐
                    │   deactivate()   │  Widget wird aus dem Baum entfernt
                    │                  │  (kann wieder eingefuegt werden)
                    └────────┬─────────┘
                             │
                    ┌────────▼─────────┐
                    │    dispose()     │  State wird endgueltig zerstoert
                    │                  │  (Ressourcen freigeben!)
                    └──────────────────┘
```

### Jede Lifecycle-Methode im Detail

#### createState()

```dart
class MeinWidget extends StatefulWidget {
  const MeinWidget({super.key});

  @override
  State<MeinWidget> createState() => _MeinWidgetState();
  // Wird genau einmal aufgerufen, wenn das Widget in den Baum eingefuegt wird.
  // Erstellt die zugehoerige State-Instanz.
}
```

#### initState()

```dart
class _MeinWidgetState extends State<MeinWidget> {
  late final TextEditingController _controller;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState(); // IMMER zuerst aufrufen!
    // Einmalige Initialisierung:
    _controller = TextEditingController(text: widget.initialerText);
    _scrollController = ScrollController();
    _ladeDaten(); // z.B. API-Aufruf starten
    print('initState aufgerufen');
  }

  // Hinweis: Hier keinen Zugriff auf context fuer InheritedWidgets!
  // Dafuer didChangeDependencies verwenden.
}
```

#### didChangeDependencies()

```dart
@override
void didChangeDependencies() {
  super.didChangeDependencies();
  // Wird aufgerufen:
  // 1. Direkt nach initState()
  // 2. Wenn sich ein InheritedWidget aendert (z.B. Theme, MediaQuery, Locale)

  // Hier ist context sicher fuer InheritedWidgets:
  final theme = Theme.of(context);
  final mediaQuery = MediaQuery.of(context);
  print('didChangeDependencies aufgerufen');
}
```

#### build()

```dart
@override
Widget build(BuildContext context) {
  // Wird aufgerufen:
  // 1. Nach initState() / didChangeDependencies()
  // 2. Nach jedem setState()
  // 3. Nach didUpdateWidget()
  // 4. Nach didChangeDependencies() (wenn InheritedWidget sich aendert)

  // WICHTIG: build() muss PURE sein (keine Seiteneffekte!)
  // KEIN setState(), kein API-Aufruf, kein File-I/O hier!
  return Text('Zaehler: $_zaehler');
}
```

#### didUpdateWidget()

```dart
@override
void didUpdateWidget(covariant MeinWidget oldWidget) {
  super.didUpdateWidget(oldWidget);
  // Wird aufgerufen, wenn das Eltern-Widget neu gebaut wird
  // und ein neues MeinWidget mit gleichem Key erstellt.

  // Nuetzlich zum Vergleichen alter und neuer Properties:
  if (oldWidget.titel != widget.titel) {
    // Titel hat sich geaendert, reagiere darauf
    _controller.text = widget.titel;
  }

  if (oldWidget.apiUrl != widget.apiUrl) {
    // Neue URL --> Daten neu laden
    _ladeDaten();
  }
}
```

#### deactivate()

```dart
@override
void deactivate() {
  // Wird aufgerufen, wenn das Widget aus dem Baum entfernt wird.
  // Das Widget KANN aber wieder eingefuegt werden (z.B. bei GlobalKey).
  // Selten direkt verwendet.
  print('deactivate aufgerufen');
  super.deactivate();
}
```

#### dispose()

```dart
@override
void dispose() {
  // Wird aufgerufen, wenn der State endgueltig zerstoert wird.
  // HIER alle Ressourcen freigeben:
  _controller.dispose();
  _scrollController.dispose();
  _timer?.cancel();
  _subscription?.cancel();
  _animationController.dispose();
  _focusNode.dispose();
  print('dispose aufgerufen');
  super.dispose(); // IMMER zuletzt aufrufen!
}
```

> **C++-Vergleich:** `dispose()` ist vergleichbar mit einem Destruktor in C++. Hier gibst du alle Ressourcen frei, die du in `initState()` allokiert hast. In C++ wuerde RAII das automatisch erledigen -- in Flutter musst du es explizit machen.

### Vollstaendiges Lifecycle-Beispiel

```dart
class LifecycleDemo extends StatefulWidget {
  const LifecycleDemo({super.key, required this.titel});
  final String titel;

  @override
  State<LifecycleDemo> createState() {
    print('1. createState()');
    return _LifecycleDemoState();
  }
}

class _LifecycleDemoState extends State<LifecycleDemo> {
  int _zaehler = 0;

  @override
  void initState() {
    super.initState();
    print('2. initState()');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    print('3. didChangeDependencies()');
  }

  @override
  Widget build(BuildContext context) {
    print('4. build()');
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('${widget.titel}: $_zaehler'),
        ElevatedButton(
          onPressed: () {
            print('--- setState aufgerufen ---');
            setState(() => _zaehler++);
          },
          child: const Text('+1'),
        ),
      ],
    );
  }

  @override
  void didUpdateWidget(covariant LifecycleDemo oldWidget) {
    super.didUpdateWidget(oldWidget);
    print('5. didUpdateWidget() - alter Titel: ${oldWidget.titel}, neuer Titel: ${widget.titel}');
  }

  @override
  void deactivate() {
    print('6. deactivate()');
    super.deactivate();
  }

  @override
  void dispose() {
    print('7. dispose()');
    super.dispose();
  }
}
```

Ausgabe beim Erstellen:
```
1. createState()
2. initState()
3. didChangeDependencies()
4. build()
```

Ausgabe bei Button-Klick:
```
--- setState aufgerufen ---
4. build()
```

---

## 5. Wann StatelessWidget vs. StatefulWidget?

### Entscheidungshilfe

```
Braucht das Widget veraenderlichen Zustand?
    │
    ├── NEIN → StatelessWidget
    │          Beispiele: Text-Label, Icon, statische Karte
    │
    └── JA  → Kann der State vom Eltern-Widget verwaltet werden?
              │
              ├── JA  → StatelessWidget (State wird als Parameter uebergeben)
              │          Beispiel: Anzeige-Widget bekommt Daten als Props
              │
              └── NEIN → StatefulWidget
                         Beispiele: Zaehler, Formulare, Animationen, Timer
```

### Beispiele

```dart
// StatelessWidget: Zeigt nur Daten an (bekommt alles als Parameter)
class BenutzerKarte extends StatelessWidget {
  const BenutzerKarte({super.key, required this.name, required this.alter});
  final String name;
  final int alter;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(name),
        subtitle: Text('$alter Jahre'),
      ),
    );
  }
}

// StatefulWidget: Verwaltet eigenen Zustand
class FavoritButton extends StatefulWidget {
  const FavoritButton({super.key});

  @override
  State<FavoritButton> createState() => _FavoritButtonState();
}

class _FavoritButtonState extends State<FavoritButton> {
  bool _istFavorit = false;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        _istFavorit ? Icons.favorite : Icons.favorite_border,
        color: _istFavorit ? Colors.red : null,
      ),
      onPressed: () {
        setState(() {
          _istFavorit = !_istFavorit;
        });
      },
    );
  }
}
```

---

## 6. Keys -- Warum sie wichtig sind

Keys helfen Flutter, Widgets im Baum eindeutig zu identifizieren. Sie sind besonders wichtig bei Listen und wenn Widgets ihre Position aendern.

### Das Problem ohne Keys

```dart
// Stell dir vor, du hast eine Liste von Widgets mit eigenem State:
Column(
  children: [
    CounterWidget(farbe: Colors.red),    // State: zaehler = 5
    CounterWidget(farbe: Colors.blue),   // State: zaehler = 3
  ],
)

// Wenn du die Reihenfolge tauschst OHNE Keys:
Column(
  children: [
    CounterWidget(farbe: Colors.blue),   // State: zaehler = 5 ← FALSCH!
    CounterWidget(farbe: Colors.red),    // State: zaehler = 3 ← FALSCH!
  ],
)
// Flutter ordnet den State nach POSITION zu, nicht nach Widget-Identitaet!
// Die Farben aendern sich, aber der State bleibt an der alten Position.
```

### Die Loesung mit Keys

```dart
Column(
  children: [
    CounterWidget(key: const ValueKey('rot'), farbe: Colors.red),
    CounterWidget(key: const ValueKey('blau'), farbe: Colors.blue),
  ],
)
// Jetzt kann Flutter die Widgets korrekt zuordnen, auch bei Neuordnung.
```

### Key-Typen

#### ValueKey

Identifiziert ein Widget anhand eines Wertes:

```dart
// Fuer einfache Werte (String, int, etc.)
ListView.builder(
  itemCount: benutzer.length,
  itemBuilder: (context, index) {
    final user = benutzer[index];
    return ListTile(
      key: ValueKey(user.id),  // Eindeutige ID
      title: Text(user.name),
    );
  },
)
```

#### ObjectKey

Identifiziert anhand einer Objekt-Referenz:

```dart
// Wenn das Objekt selbst der Identifikator ist
ListTile(
  key: ObjectKey(meinObjekt),
  title: Text(meinObjekt.name),
)
```

#### UniqueKey

Erzeugt jedes Mal einen neuen, einzigartigen Key:

```dart
// Erzwingt, dass das Widget IMMER neu erstellt wird
// Vorsicht: State geht verloren!
AnimatedWidget(
  key: UniqueKey(),  // Jedes Mal neuer State
  child: const Text('Immer neu'),
)
```

#### GlobalKey

Erlaubt Zugriff auf State und Context eines Widgets von ausserhalb:

```dart
// GlobalKey erstellen
final _formKey = GlobalKey<FormState>();

// Im Widget verwenden
Form(
  key: _formKey,
  child: Column(
    children: [
      TextFormField(
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Bitte ausfuellen';
          }
          return null;
        },
      ),
      ElevatedButton(
        onPressed: () {
          // Auf den Form-State zugreifen:
          if (_formKey.currentState!.validate()) {
            // Formular ist gueltig
          }
        },
        child: const Text('Absenden'),
      ),
    ],
  ),
)
```

> **Wann welchen Key verwenden?**
> - `ValueKey`: Wenn du einen eindeutigen Wert hast (ID, Name) -- **haeufigster Fall**
> - `ObjectKey`: Wenn das ganze Objekt als Identifikator dient
> - `UniqueKey`: Wenn du bewusst State verwerfen willst
> - `GlobalKey`: Wenn du von ausserhalb auf ein Widget zugreifen musst (selten, lieber vermeiden)

---

## 7. State nach oben heben (Lifting State Up)

Wenn mehrere Widgets denselben State teilen muessen, wird der State in ein gemeinsames Eltern-Widget verschoben.

> **React-Vergleich:** Das Konzept ist identisch zu "Lifting State Up" in React. State wird im naechsten gemeinsamen Vorfahren gehalten und per Callbacks und Props nach unten gereicht.

### Problem: Zwei Widgets brauchen denselben State

```dart
// SCHLECHT: Jedes Widget hat seinen eigenen State
// Die Widgets wissen nichts voneinander

class AnzeigeWidget extends StatelessWidget {
  // Woher bekommt es den Zaehler?
}

class ButtonWidget extends StatelessWidget {
  // Wie kann es den Zaehler aendern?
}
```

### Loesung: State im Eltern-Widget

```dart
import 'package:flutter/material.dart';

// Eltern-Widget haelt den State
class ZaehlerSeite extends StatefulWidget {
  const ZaehlerSeite({super.key});

  @override
  State<ZaehlerSeite> createState() => _ZaehlerSeiteState();
}

class _ZaehlerSeiteState extends State<ZaehlerSeite> {
  int _zaehler = 0;

  void _erhoehen() {
    setState(() => _zaehler++);
  }

  void _verringern() {
    setState(() => _zaehler--);
  }

  void _zuruecksetzen() {
    setState(() => _zaehler = 0);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Kind-Widget 1: Bekommt den Wert als Parameter
        ZaehlerAnzeige(wert: _zaehler),
        const SizedBox(height: 24),
        // Kind-Widget 2: Bekommt Callbacks als Parameter
        ZaehlerButtons(
          onErhoehen: _erhoehen,
          onVerringern: _verringern,
          onZuruecksetzen: _zuruecksetzen,
        ),
      ],
    );
  }
}

// Kind-Widget: Zeigt den Wert an (StatelessWidget genuegt!)
class ZaehlerAnzeige extends StatelessWidget {
  const ZaehlerAnzeige({super.key, required this.wert});
  final int wert;

  @override
  Widget build(BuildContext context) {
    return Text(
      '$wert',
      style: Theme.of(context).textTheme.displayLarge,
    );
  }
}

// Kind-Widget: Stellt Buttons bereit (StatelessWidget genuegt!)
class ZaehlerButtons extends StatelessWidget {
  const ZaehlerButtons({
    super.key,
    required this.onErhoehen,
    required this.onVerringern,
    required this.onZuruecksetzen,
  });

  final VoidCallback onErhoehen;
  final VoidCallback onVerringern;
  final VoidCallback onZuruecksetzen;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: onVerringern,
          child: const Icon(Icons.remove),
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: onZuruecksetzen,
          child: const Text('Reset'),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: onErhoehen,
          child: const Icon(Icons.add),
        ),
      ],
    );
  }
}
```

### Wann State nach oben heben?

```
Widget A braucht Zustand X
Widget B braucht auch Zustand X
    ↓
Finde den naechsten gemeinsamen Vorfahren von A und B
    ↓
Verschiebe Zustand X dorthin
    ↓
Reiche Zustand X als Parameter nach unten
Reiche Callbacks zum Aendern nach unten
```

> **Achtung:** Wenn der State sehr tief gereicht werden muss (ueber viele Ebenen), wird "Lifting State Up" unhandlich. Dafuer gibt es State-Management-Loesungen wie Provider, Riverpod oder BLoC (Woche 3, Modul 9).

---

## 8. Praktische Beispiele

### Beispiel 1: Toggle mit Animation

```dart
class AnimierterToggle extends StatefulWidget {
  const AnimierterToggle({super.key});

  @override
  State<AnimierterToggle> createState() => _AnimierterToggleState();
}

class _AnimierterToggleState extends State<AnimierterToggle> {
  bool _istAktiv = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _istAktiv = !_istAktiv;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: _istAktiv ? Colors.green : Colors.red,
          borderRadius: BorderRadius.circular(_istAktiv ? 50 : 16),
          boxShadow: [
            BoxShadow(
              color: (_istAktiv ? Colors.green : Colors.red)
                  .withValues(alpha: 0.4),
              blurRadius: _istAktiv ? 20 : 5,
              spreadRadius: _istAktiv ? 2 : 0,
            ),
          ],
        ),
        child: Center(
          child: Icon(
            _istAktiv ? Icons.check : Icons.close,
            color: Colors.white,
            size: 48,
          ),
        ),
      ),
    );
  }
}
```

### Beispiel 2: Einfaches Formular mit State

```dart
class EinfachesFormular extends StatefulWidget {
  const EinfachesFormular({super.key});

  @override
  State<EinfachesFormular> createState() => _EinfachesFormularState();
}

class _EinfachesFormularState extends State<EinfachesFormular> {
  final _controller = TextEditingController();
  final List<String> _eintraege = [];

  @override
  void dispose() {
    _controller.dispose(); // WICHTIG: Controller freigeben!
    super.dispose();
  }

  void _eintragHinzufuegen() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _eintraege.add(text);
        _controller.clear();
      });
    }
  }

  void _eintragEntfernen(int index) {
    setState(() {
      _eintraege.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Einfache Liste')),
      body: Column(
        children: [
          // Eingabefeld
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Neuer Eintrag...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _eintragHinzufuegen(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _eintragHinzufuegen,
                  child: const Icon(Icons.add),
                ),
              ],
            ),
          ),

          // Anzahl der Eintraege
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('${_eintraege.length} Eintraege'),
          ),

          // Liste der Eintraege
          Expanded(
            child: ListView.builder(
              itemCount: _eintraege.length,
              itemBuilder: (context, index) {
                return ListTile(
                  key: ValueKey('$index-${_eintraege[index]}'),
                  title: Text(_eintraege[index]),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _eintragEntfernen(index),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
```

### Beispiel 3: Mehrere State-Variablen

```dart
class ProfilEditor extends StatefulWidget {
  const ProfilEditor({super.key});

  @override
  State<ProfilEditor> createState() => _ProfilEditorState();
}

class _ProfilEditorState extends State<ProfilEditor> {
  String _name = 'Max Mustermann';
  bool _darkMode = false;
  double _schriftgroesse = 16.0;
  Color _lieblingsfarbe = Colors.blue;

  final List<Color> _farben = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.purple,
    Colors.orange,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil-Editor')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Vorschau
            Card(
              color: _darkMode ? Colors.grey.shade900 : Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    _name,
                    style: TextStyle(
                      fontSize: _schriftgroesse,
                      color: _darkMode ? Colors.white : _lieblingsfarbe,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Dark Mode Toggle
            SwitchListTile(
              title: const Text('Dark Mode'),
              value: _darkMode,
              onChanged: (wert) {
                setState(() => _darkMode = wert);
              },
            ),

            // Schriftgroesse Slider
            ListTile(
              title: Text('Schriftgroesse: ${_schriftgroesse.toInt()}'),
              subtitle: Slider(
                value: _schriftgroesse,
                min: 12,
                max: 48,
                divisions: 36,
                label: '${_schriftgroesse.toInt()}',
                onChanged: (wert) {
                  setState(() => _schriftgroesse = wert);
                },
              ),
            ),

            // Farbauswahl
            const Text('Lieblingsfarbe:'),
            const SizedBox(height: 8),
            Row(
              children: _farben.map((farbe) {
                final istGewaehlt = farbe == _lieblingsfarbe;
                return GestureDetector(
                  onTap: () {
                    setState(() => _lieblingsfarbe = farbe);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: farbe,
                      shape: BoxShape.circle,
                      border: istGewaehlt
                          ? Border.all(color: Colors.black, width: 3)
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 9. Zusammenfassung

| Konzept | Merke dir |
|---------|-----------|
| StatefulWidget | Zwei Klassen: Widget (immutable) + State (mutable) |
| setState() | Einziger Weg, das UI bei State-Aenderung zu aktualisieren |
| initState() | Einmalige Initialisierung (Controller, Timer, etc.) |
| dispose() | Ressourcen freigeben (Controller, Timer, Subscriptions) |
| mounted | Vor setState() nach async-Operationen pruefen |
| Keys | Helfen Flutter, Widgets korrekt zuzuordnen (besonders in Listen) |
| Lifting State Up | State im naechsten gemeinsamen Vorfahren halten |
| widget-Getter | Zugriff auf Widget-Properties aus der State-Klasse |

### Haeufige Fehler

1. **`dispose()` vergessen:** Memory Leaks durch nicht freigegebene Controller/Timer
2. **`setState()` nach dispose:** Pruefe immer `mounted` bei async-Code
3. **`setState()` in build:** Fuehrt zu Endlosschleife
4. **Zu viel State in einem Widget:** Besser aufteilen und State heben
5. **Keys vergessen bei dynamischen Listen:** Fuehrt zu falscher State-Zuordnung
