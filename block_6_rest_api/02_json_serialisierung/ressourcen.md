# Ressourcen: JSON Serialisierung

## Offizielle Dokumentation

- [dart:convert](https://api.dart.dev/stable/dart-convert/dart-convert-library.html)
- [json_serializable](https://pub.dev/packages/json_serializable)
- [json_annotation](https://pub.dev/packages/json_annotation)
- [JSON and serialization (Flutter)](https://docs.flutter.dev/data-and-backend/serialization/json)

## Cheat Sheet: Basics

```dart
import 'dart:convert';

// JSON String → Map
final map = jsonDecode('{"key": "value"}') as Map<String, dynamic>;

// Map → JSON String
final json = jsonEncode({'key': 'value'});

// Pretty Print
final pretty = JsonEncoder.withIndent('  ').convert(data);
```

## Cheat Sheet: Model-Klasse

```dart
class User {
  final String id;
  final String name;
  final String? email;  // Optional

  User({required this.id, required this.name, this.email});

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'] as String,
    name: json['name'] as String,
    email: json['email'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    if (email != null) 'email': email,
  };
}
```

## Cheat Sheet: Verschachtelte Objekte

```dart
factory Parent.fromJson(Map<String, dynamic> json) => Parent(
  child: Child.fromJson(json['child'] as Map<String, dynamic>),
);

Map<String, dynamic> toJson() => {
  'child': child.toJson(),
};
```

## Cheat Sheet: Listen

```dart
// JSON → List<Model>
final items = (json['items'] as List)
    .map((e) => Item.fromJson(e as Map<String, dynamic>))
    .toList();

// List<Model> → JSON
'items': items.map((e) => e.toJson()).toList(),
```

## Cheat Sheet: DateTime

```dart
// Parse
final date = DateTime.parse(json['date'] as String);

// Serialize
'date': date.toIso8601String(),
```

## Cheat Sheet: Enums

```dart
// Parse
final status = Status.values.firstWhere(
  (e) => e.name == json['status'],
  orElse: () => Status.unknown,
);

// Serialize
'status': status.name,
```

## Cheat Sheet: json_serializable

```yaml
# pubspec.yaml
dependencies:
  json_annotation: ^4.8.0
dev_dependencies:
  build_runner: ^2.4.0
  json_serializable: ^6.7.0
```

```dart
import 'package:json_annotation/json_annotation.dart';
part 'model.g.dart';

@JsonSerializable()
class Model {
  final String id;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @JsonKey(includeIfNull: false)
  final String? optional;

  Model({required this.id, required this.createdAt, this.optional});

  factory Model.fromJson(Map<String, dynamic> json) => _$ModelFromJson(json);
  Map<String, dynamic> toJson() => _$ModelToJson(this);
}
```

```bash
# Code generieren
dart run build_runner build

# Watch mode
dart run build_runner watch
```

## Typsichere Konvertierung

```dart
// Sicher zu int
int parseId(dynamic value) {
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

// Sicher zu double
double parsePrice(dynamic value) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}
```

## JSON Tools

- [JSON Formatter](https://jsonformatter.org/)
- [JSON to Dart](https://javiercbk.github.io/json_to_dart/)
- [quicktype](https://quicktype.io/) - JSON zu Code
