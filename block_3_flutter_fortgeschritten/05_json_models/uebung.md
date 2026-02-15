# Übung 3.5: JSON & Model-Klassen

## Ziel

Model-Klassen für eine API erstellen und JSON-Daten verarbeiten.

---

## Aufgabe 1: Einfaches Model (15 min)

Gegeben ist folgender JSON:

```json
{
  "id": 1,
  "title": "Flutter Basics",
  "author": "Max Mustermann",
  "pages": 350,
  "published": true,
  "rating": 4.5
}
```

Erstelle eine `Book`-Klasse mit:
- `fromJson` Factory Constructor
- `toJson` Methode
- `copyWith` Methode
- `toString` Override

---

## Aufgabe 2: Verschachtelte Objekte (20 min)

JSON-Struktur:

```json
{
  "id": 1,
  "name": "Flutter Developers",
  "description": "Eine Gruppe für Flutter Enthusiasten",
  "admin": {
    "id": 42,
    "username": "flutter_pro",
    "email": "admin@example.com"
  },
  "members_count": 1250,
  "created_at": "2024-01-15T10:30:00Z",
  "tags": ["flutter", "dart", "mobile"]
}
```

Erstelle die Model-Klassen:
- `Group` (Hauptklasse)
- `GroupAdmin` (verschachteltes Objekt)

Achte auf:
- DateTime Parsing für `created_at`
- Liste für `tags`

---

## Aufgabe 3: Liste von Objekten (20 min)

API Response:

```json
{
  "success": true,
  "data": {
    "products": [
      {
        "id": 1,
        "name": "Laptop",
        "price": 999.99,
        "category": "electronics",
        "in_stock": true
      },
      {
        "id": 2,
        "name": "Headphones",
        "price": 149.99,
        "category": "electronics",
        "in_stock": false
      }
    ],
    "total": 2,
    "currency": "EUR"
  }
}
```

Erstelle:
- `Product` Model
- `ProductsResponse` Model (enthält Liste von Products)
- `ApiResponse<T>` Generic Wrapper

---

## Aufgabe 4: Enum Handling (15 min)

```json
{
  "id": 1,
  "title": "Wichtige Aufgabe",
  "priority": "high",
  "status": "in_progress"
}
```

Erstelle:
- `Priority` Enum (low, medium, high)
- `TaskStatus` Enum (todo, in_progress, done, cancelled)
- `Task` Model mit korrektem Enum-Parsing

Behandle unbekannte Enum-Werte mit einem Default.

---

## Aufgabe 5: json_serializable (30 min)

Rüste die `Product`-Klasse aus Aufgabe 3 auf `json_serializable` um:

1. Füge Dependencies hinzu:
   ```yaml
   dependencies:
     json_annotation: ^4.8.1
   dev_dependencies:
     build_runner: ^2.4.8
     json_serializable: ^6.7.1
   ```

2. Erstelle die annotierte Klasse:
   ```dart
   @JsonSerializable()
   class Product {
     final int id;

     @JsonKey(name: 'product_name')
     final String name;

     @JsonKey(defaultValue: 0.0)
     final double price;

     @JsonKey(name: 'in_stock', defaultValue: false)
     final bool inStock;

     // ...
   }
   ```

3. Führe den Build-Runner aus

4. Teste mit verschiedenen JSON-Inputs

---

## Aufgabe 6: Fehlerbehandlung (15 min)

Schreibe eine `safeParse`-Funktion, die JSON-Fehler abfängt:

```dart
T? safeParse<T>(
  String jsonString,
  T Function(Map<String, dynamic>) fromJson,
) {
  // Implementiere:
  // - FormatException abfangen (ungültiges JSON)
  // - TypeError abfangen (fehlende/falsche Felder)
  // - null zurückgeben bei Fehlern (oder Exception werfen)
}
```

Teste mit:
- Gültigem JSON
- Ungültigem JSON-String
- JSON mit fehlenden Feldern
- JSON mit falschen Typen

---

## Aufgabe 7: Praxis-Integration (25 min)

Integriere die Models in eine echte API-Anbindung:

1. Nutze die API: `https://jsonplaceholder.typicode.com/users`

2. Erstelle das `User`-Model basierend auf der API-Response:
   ```json
   {
     "id": 1,
     "name": "Leanne Graham",
     "username": "Bret",
     "email": "Sincere@april.biz",
     "address": {
       "street": "Kulas Light",
       "suite": "Apt. 556",
       "city": "Gwenborough",
       "zipcode": "92998-3874",
       "geo": {
         "lat": "-37.3159",
         "lng": "81.1496"
       }
     },
     "phone": "1-770-736-8031 x56442",
     "website": "hildegard.org",
     "company": {
       "name": "Romaguera-Crona",
       "catchPhrase": "Multi-layered client-server neural-net",
       "bs": "harness real-time e-markets"
     }
   }
   ```

3. Lade alle User und zeige sie in einer ListView an

---

## Bonus: Freezed Package

Installiere `freezed` und erstelle ein immutables Model:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

@freezed
class User with _$User {
  const factory User({
    required int id,
    required String name,
    String? email,
    @Default(false) bool isAdmin,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
```

Vergleiche den generierten Code mit manuellem Code.

---

## Abgabe-Checkliste

- [ ] Book Model mit allen Methoden
- [ ] Group/GroupAdmin verschachtelte Models
- [ ] Product Model mit Liste
- [ ] Enums korrekt geparst
- [ ] json_serializable funktioniert
- [ ] Fehlerbehandlung implementiert
- [ ] User-API angebunden
- [ ] (Bonus) Freezed ausprobiert
