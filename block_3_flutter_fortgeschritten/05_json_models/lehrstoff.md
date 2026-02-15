# Einheit 3.5: JSON & Model-Klassen

## Lernziele

Nach dieser Einheit kannst du:
- JSON-Daten in Dart-Objekte konvertieren
- `fromJson` und `toJson` Methoden implementieren
- Verschachtelte JSON-Strukturen verarbeiten
- `json_serializable` für Code-Generierung nutzen
- Best Practices für Model-Klassen anwenden

---

## 1. JSON Grundlagen in Dart

### Import

```dart
import 'dart:convert';
```

### JSON parsen und erzeugen

```dart
// JSON String → Dart Map
final jsonString = '{"name": "Max", "age": 25}';
final Map<String, dynamic> data = jsonDecode(jsonString);

print(data['name']);  // Max
print(data['age']);   // 25

// Dart Map → JSON String
final map = {'name': 'Max', 'age': 25};
final json = jsonEncode(map);

print(json);  // {"name":"Max","age":25}
```

### JSON Arrays

```dart
// JSON Array → Dart List
final jsonArray = '[{"id": 1}, {"id": 2}]';
final List<dynamic> list = jsonDecode(jsonArray);

// Dart List → JSON String
final items = [{'id': 1}, {'id': 2}];
final json = jsonEncode(items);
```

---

## 2. Model-Klassen erstellen

### Einfaches Model

```dart
class User {
  final int id;
  final String name;
  final String email;

  User({
    required this.id,
    required this.name,
    required this.email,
  });

  // Factory Constructor für JSON → Object
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
    );
  }

  // Method für Object → JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
    };
  }
}
```

### Verwendung

```dart
// API Response parsen
final response = await http.get(Uri.parse('https://api.example.com/user/1'));
final json = jsonDecode(response.body);
final user = User.fromJson(json);

// Für POST Request
final newUser = User(id: 0, name: 'Max', email: 'max@example.com');
final body = jsonEncode(newUser.toJson());
```

---

## 3. Optionale Felder und Defaults

```dart
class Post {
  final int id;
  final String title;
  final String? subtitle;      // Nullable
  final int likes;
  final DateTime createdAt;

  Post({
    required this.id,
    required this.title,
    this.subtitle,              // Optional
    this.likes = 0,             // Default
    required this.createdAt,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] as int,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String?,  // Kann null sein
      likes: json['likes'] as int? ?? 0,      // Default wenn null
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      if (subtitle != null) 'subtitle': subtitle,  // Nur wenn nicht null
      'likes': likes,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
```

---

## 4. Verschachtelte Objekte

### Einfache Verschachtelung

```dart
class Address {
  final String street;
  final String city;
  final String zipCode;

  Address({
    required this.street,
    required this.city,
    required this.zipCode,
  });

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
  final int id;
  final String name;
  final Address address;  // Verschachteltes Objekt

  User({
    required this.id,
    required this.name,
    required this.address,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String,
      // Verschachteltes Objekt parsen
      address: Address.fromJson(json['address'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'address': address.toJson(),  // Rekursiv
  };
}
```

### Listen von Objekten

```dart
class Author {
  final String name;
  final List<Book> books;

  Author({required this.name, required this.books});

  factory Author.fromJson(Map<String, dynamic> json) {
    return Author(
      name: json['name'] as String,
      books: (json['books'] as List<dynamic>)
          .map((bookJson) => Book.fromJson(bookJson as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'books': books.map((book) => book.toJson()).toList(),
  };
}

class Book {
  final String title;
  final int year;

  Book({required this.title, required this.year});

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      title: json['title'] as String,
      year: json['year'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'year': year,
  };
}
```

---

## 5. Enums in JSON

```dart
enum Status {
  pending,
  active,
  completed,
  cancelled;

  // String → Enum
  static Status fromJson(String json) {
    return Status.values.firstWhere(
      (e) => e.name == json,
      orElse: () => Status.pending,
    );
  }

  // Enum → String
  String toJson() => name;
}

class Task {
  final String title;
  final Status status;

  Task({required this.title, required this.status});

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      title: json['title'] as String,
      status: Status.fromJson(json['status'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'status': status.toJson(),
  };
}
```

---

## 6. copyWith Pattern

```dart
class User {
  final int id;
  final String name;
  final String email;

  User({
    required this.id,
    required this.name,
    required this.email,
  });

  // Kopie mit optionalen Änderungen
  User copyWith({
    int? id,
    String? name,
    String? email,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
    );
  }

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'] as int,
    name: json['name'] as String,
    email: json['email'] as String,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
  };

  // Für Debugging
  @override
  String toString() => 'User(id: $id, name: $name, email: $email)';

  // Für Vergleiche
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          id == other.id &&
          name == other.name &&
          email == other.email;

  @override
  int get hashCode => Object.hash(id, name, email);
}
```

---

## 7. json_serializable (Code-Generierung)

### Setup

```yaml
# pubspec.yaml
dependencies:
  json_annotation: ^4.8.1

dev_dependencies:
  build_runner: ^2.4.8
  json_serializable: ^6.7.1
```

### Model mit Annotations

```dart
import 'package:json_annotation/json_annotation.dart';

// Generierte Datei importieren (wird erstellt)
part 'user.g.dart';

@JsonSerializable()
class User {
  final int id;
  final String name;

  @JsonKey(name: 'email_address')  // Anderer JSON-Schlüssel
  final String email;

  @JsonKey(defaultValue: false)    // Default-Wert
  final bool isVerified;

  @JsonKey(includeIfNull: false)   // Nicht in JSON wenn null
  final String? bio;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.isVerified,
    this.bio,
  });

  // Generierte Methoden verwenden
  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);
}
```

### Code generieren

```bash
# Einmalig generieren
flutter pub run build_runner build

# Kontinuierlich bei Änderungen (Watch-Mode)
flutter pub run build_runner watch

# Konflikte lösen
flutter pub run build_runner build --delete-conflicting-outputs
```

### Generierte Datei (user.g.dart)

```dart
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

User _$UserFromJson(Map<String, dynamic> json) => User(
  id: json['id'] as int,
  name: json['name'] as String,
  email: json['email_address'] as String,
  isVerified: json['isVerified'] as bool? ?? false,
  bio: json['bio'] as String?,
);

Map<String, dynamic> _$UserToJson(User instance) {
  final val = <String, dynamic>{
    'id': instance.id,
    'name': instance.name,
    'email_address': instance.email,
    'isVerified': instance.isVerified,
  };

  if (instance.bio != null) {
    val['bio'] = instance.bio;
  }

  return val;
}
```

### JsonKey Optionen

```dart
@JsonKey(
  name: 'user_name',           // JSON-Schlüssel
  defaultValue: 'Unknown',     // Default wenn null/fehlt
  includeIfNull: false,        // Nicht serialisieren wenn null
  fromJson: _dateFromJson,     // Custom Parser
  toJson: _dateToJson,         // Custom Serializer
  ignore: true,                // Komplett ignorieren
  required: true,              // Muss vorhanden sein
)
```

### Verschachtelte Objekte

```dart
@JsonSerializable(explicitToJson: true)  // Wichtig für verschachtelte Objekte
class Order {
  final int id;
  final User customer;         // Verschachteltes Objekt
  final List<Product> items;   // Liste von Objekten

  Order({
    required this.id,
    required this.customer,
    required this.items,
  });

  factory Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);
  Map<String, dynamic> toJson() => _$OrderToJson(this);
}
```

---

## 8. Praktisches Beispiel: API Response

### JSON vom Server

```json
{
  "data": {
    "users": [
      {
        "id": 1,
        "name": "Max Mustermann",
        "email": "max@example.com",
        "profile": {
          "avatar_url": "https://...",
          "bio": "Flutter Developer"
        },
        "created_at": "2024-01-15T10:30:00Z"
      }
    ],
    "total": 42,
    "page": 1
  },
  "success": true
}
```

### Model-Klassen

```dart
// api_response.dart
class ApiResponse<T> {
  final T data;
  final bool success;

  ApiResponse({required this.data, required this.success});

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    return ApiResponse(
      data: fromJsonT(json['data'] as Map<String, dynamic>),
      success: json['success'] as bool,
    );
  }
}

// users_data.dart
class UsersData {
  final List<User> users;
  final int total;
  final int page;

  UsersData({
    required this.users,
    required this.total,
    required this.page,
  });

  factory UsersData.fromJson(Map<String, dynamic> json) {
    return UsersData(
      users: (json['users'] as List<dynamic>)
          .map((u) => User.fromJson(u as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int,
      page: json['page'] as int,
    );
  }
}

// user.dart
class User {
  final int id;
  final String name;
  final String email;
  final Profile profile;
  final DateTime createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.profile,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      profile: Profile.fromJson(json['profile'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

// profile.dart
class Profile {
  final String avatarUrl;
  final String? bio;

  Profile({required this.avatarUrl, this.bio});

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      avatarUrl: json['avatar_url'] as String,
      bio: json['bio'] as String?,
    );
  }
}
```

### Verwendung

```dart
final response = await http.get(Uri.parse('https://api.example.com/users'));
final json = jsonDecode(response.body) as Map<String, dynamic>;

final apiResponse = ApiResponse.fromJson(json, UsersData.fromJson);

if (apiResponse.success) {
  for (final user in apiResponse.data.users) {
    print('${user.name}: ${user.profile.bio}');
  }
}
```

---

## Zusammenfassung

| Ansatz | Vorteile | Nachteile |
|--------|----------|-----------|
| Manuell | Volle Kontrolle, kein Build-Step | Fehleranfällig, viel Code |
| json_serializable | Weniger Code, Type-Safe | Build-Step nötig |

**Best Practices:**
1. Immutable Models (alle Felder `final`)
2. `copyWith` für Änderungen
3. `toString`, `==`, `hashCode` implementieren
4. Factory Constructor für `fromJson`
5. Nullable Felder explizit markieren
6. `explicitToJson: true` bei verschachtelten Objekten
