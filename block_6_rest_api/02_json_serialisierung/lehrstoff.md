# Einheit 6.2: JSON Serialisierung

## Lernziele

Nach dieser Einheit kannst du:
- JSON in Dart parsen und generieren
- Model-Klassen mit `fromJson`/`toJson` erstellen
- Verschachtelte Objekte und Listen serialisieren
- Das `json_serializable` Package für Code-Generierung nutzen

---

## JSON Grundlagen in Dart

### dart:convert

```dart
import 'dart:convert';

void main() {
  // JSON String → Dart Map
  final jsonString = '{"name": "Max", "age": 30}';
  final map = jsonDecode(jsonString) as Map<String, dynamic>;
  print(map['name']); // Max

  // Dart Map → JSON String
  final data = {'name': 'Anna', 'age': 25};
  final json = jsonEncode(data);
  print(json); // {"name":"Anna","age":25}
}
```

### JSON-Typen in Dart

| JSON | Dart |
|------|------|
| `string` | `String` |
| `number` | `int` oder `double` |
| `boolean` | `bool` |
| `null` | `null` |
| `array` | `List<dynamic>` |
| `object` | `Map<String, dynamic>` |

---

## Model-Klassen

### Einfache Model-Klasse

```dart
class User {
  final String id;
  final String name;
  final String email;
  final int age;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.age,
  });

  // JSON → User
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      age: json['age'] as int,
    );
  }

  // User → JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'age': age,
    };
  }
}
```

### Verwendung

```dart
// JSON parsen
final jsonString = '{"id": "1", "name": "Max", "email": "max@example.com", "age": 30}';
final map = jsonDecode(jsonString) as Map<String, dynamic>;
final user = User.fromJson(map);

// Zu JSON serialisieren
final json = jsonEncode(user.toJson());
```

---

## Optionale Felder

### Mit Null-Safety

```dart
class Product {
  final String id;
  final String name;
  final double price;
  final String? description;  // Optional
  final String? imageUrl;     // Optional

  Product({
    required this.id,
    required this.name,
    required this.price,
    this.description,
    this.imageUrl,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      if (description != null) 'description': description,
      if (imageUrl != null) 'image_url': imageUrl,
    };
  }
}
```

### Default-Werte

```dart
factory Product.fromJson(Map<String, dynamic> json) {
  return Product(
    id: json['id'] as String,
    name: json['name'] as String,
    price: (json['price'] as num?)?.toDouble() ?? 0.0,
    description: json['description'] as String? ?? '',
    stock: json['stock'] as int? ?? 0,
  );
}
```

---

## Verschachtelte Objekte

### Einfache Verschachtelung

```dart
class Address {
  final String street;
  final String city;
  final String zipCode;

  Address({required this.street, required this.city, required this.zipCode});

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      street: json['street'] as String,
      city: json['city'] as String,
      zipCode: json['zip_code'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'street': street,
    'city': city,
    'zip_code': zipCode,
  };
}

class User {
  final String id;
  final String name;
  final Address address;  // Verschachteltes Objekt

  User({required this.id, required this.name, required this.address});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      address: Address.fromJson(json['address'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'address': address.toJson(),
  };
}
```

### JSON-Beispiel

```json
{
  "id": "123",
  "name": "Max Mustermann",
  "address": {
    "street": "Hauptstraße 1",
    "city": "Berlin",
    "zip_code": "10115"
  }
}
```

---

## Listen serialisieren

### Liste von Objekten

```dart
class Order {
  final String id;
  final List<OrderItem> items;
  final double total;

  Order({required this.id, required this.items, required this.total});

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      items: (json['items'] as List<dynamic>)
          .map((item) => OrderItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'items': items.map((item) => item.toJson()).toList(),
    'total': total,
  };
}

class OrderItem {
  final String productId;
  final int quantity;
  final double price;

  OrderItem({required this.productId, required this.quantity, required this.price});

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['product_id'] as String,
      quantity: json['quantity'] as int,
      price: (json['price'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'product_id': productId,
    'quantity': quantity,
    'price': price,
  };
}
```

---

## DateTime-Serialisierung

### ISO 8601 Format

```dart
class Event {
  final String id;
  final String title;
  final DateTime startTime;
  final DateTime? endTime;

  Event({
    required this.id,
    required this.title,
    required this.startTime,
    this.endTime,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] as String,
      title: json['title'] as String,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: json['end_time'] != null
          ? DateTime.parse(json['end_time'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'start_time': startTime.toIso8601String(),
    if (endTime != null) 'end_time': endTime!.toIso8601String(),
  };
}
```

---

## Enums serialisieren

```dart
enum OrderStatus { pending, processing, shipped, delivered, cancelled }

class Order {
  final String id;
  final OrderStatus status;

  Order({required this.id, required this.status});

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      status: OrderStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => OrderStatus.pending,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'status': status.name,
  };
}
```

---

## json_serializable (Code-Generierung)

Für größere Projekte empfiehlt sich die automatische Code-Generierung.

### Setup

```yaml
# pubspec.yaml
dependencies:
  json_annotation: ^4.8.0

dev_dependencies:
  build_runner: ^2.4.0
  json_serializable: ^6.7.0
```

### Model mit Annotations

```dart
import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class User {
  final String id;
  final String name;
  final String email;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @JsonKey(includeIfNull: false)
  final String? bio;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.createdAt,
    this.bio,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);
}
```

### Code generieren

```bash
# Einmalig generieren
dart run build_runner build

# Watch-Modus (automatisch bei Änderungen)
dart run build_runner watch
```

---

## Fehlerbehandlung

### Sichere Konvertierung

```dart
class User {
  factory User.fromJson(Map<String, dynamic> json) {
    try {
      return User(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? 'Unknown',
        age: _parseAge(json['age']),
      );
    } catch (e) {
      throw FormatException('Invalid User JSON: $e');
    }
  }

  static int _parseAge(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
```

---

## Zusammenfassung

| Aufgabe | Lösung |
|---------|--------|
| JSON parsen | `jsonDecode(string)` |
| JSON generieren | `jsonEncode(map)` |
| Model von JSON | `factory Model.fromJson(Map)` |
| Model zu JSON | `Map toJson()` |
| Verschachtelt | Rekursiv `fromJson`/`toJson` aufrufen |
| Listen | `.map().toList()` |
| DateTime | `DateTime.parse()` / `.toIso8601String()` |
| Automatisch | `json_serializable` Package |

---

## Nächste Schritte

In der nächsten Einheit lernst du **Request Body Parsing**: Wie du JSON-Daten aus HTTP-Requests liest und verarbeitest.
