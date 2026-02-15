# Lösung 3.5: JSON & Model-Klassen

## Aufgabe 1: Book Model

```dart
class Book {
  final int id;
  final String title;
  final String author;
  final int pages;
  final bool published;
  final double rating;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.pages,
    required this.published,
    required this.rating,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'] as int,
      title: json['title'] as String,
      author: json['author'] as String,
      pages: json['pages'] as int,
      published: json['published'] as bool,
      rating: (json['rating'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'pages': pages,
      'published': published,
      'rating': rating,
    };
  }

  Book copyWith({
    int? id,
    String? title,
    String? author,
    int? pages,
    bool? published,
    double? rating,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      pages: pages ?? this.pages,
      published: published ?? this.published,
      rating: rating ?? this.rating,
    );
  }

  @override
  String toString() {
    return 'Book(id: $id, title: $title, author: $author, '
        'pages: $pages, published: $published, rating: $rating)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Book &&
          id == other.id &&
          title == other.title &&
          author == other.author;

  @override
  int get hashCode => Object.hash(id, title, author);
}
```

---

## Aufgabe 2: Verschachtelte Objekte

```dart
class GroupAdmin {
  final int id;
  final String username;
  final String email;

  GroupAdmin({
    required this.id,
    required this.username,
    required this.email,
  });

  factory GroupAdmin.fromJson(Map<String, dynamic> json) {
    return GroupAdmin(
      id: json['id'] as int,
      username: json['username'] as String,
      email: json['email'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'email': email,
      };
}

class Group {
  final int id;
  final String name;
  final String description;
  final GroupAdmin admin;
  final int membersCount;
  final DateTime createdAt;
  final List<String> tags;

  Group({
    required this.id,
    required this.name,
    required this.description,
    required this.admin,
    required this.membersCount,
    required this.createdAt,
    required this.tags,
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String,
      admin: GroupAdmin.fromJson(json['admin'] as Map<String, dynamic>),
      membersCount: json['members_count'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      tags: (json['tags'] as List<dynamic>).cast<String>(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'admin': admin.toJson(),
        'members_count': membersCount,
        'created_at': createdAt.toIso8601String(),
        'tags': tags,
      };
}
```

---

## Aufgabe 3: Liste von Objekten

```dart
class Product {
  final int id;
  final String name;
  final double price;
  final String category;
  final bool inStock;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.inStock,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      category: json['category'] as String,
      inStock: json['in_stock'] as bool,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'price': price,
        'category': category,
        'in_stock': inStock,
      };
}

class ProductsData {
  final List<Product> products;
  final int total;
  final String currency;

  ProductsData({
    required this.products,
    required this.total,
    required this.currency,
  });

  factory ProductsData.fromJson(Map<String, dynamic> json) {
    return ProductsData(
      products: (json['products'] as List<dynamic>)
          .map((p) => Product.fromJson(p as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int,
      currency: json['currency'] as String,
    );
  }
}

class ApiResponse<T> {
  final bool success;
  final T data;

  ApiResponse({
    required this.success,
    required this.data,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    return ApiResponse(
      success: json['success'] as bool,
      data: fromJsonT(json['data'] as Map<String, dynamic>),
    );
  }
}

// Verwendung:
// final response = ApiResponse.fromJson(json, ProductsData.fromJson);
// print(response.data.products.length);
```

---

## Aufgabe 4: Enum Handling

```dart
enum Priority {
  low,
  medium,
  high;

  static Priority fromJson(String json) {
    return Priority.values.firstWhere(
      (e) => e.name == json.toLowerCase(),
      orElse: () => Priority.medium,
    );
  }

  String toJson() => name;
}

enum TaskStatus {
  todo,
  inProgress,
  done,
  cancelled;

  static TaskStatus fromJson(String json) {
    // Handle snake_case from API
    switch (json.toLowerCase()) {
      case 'todo':
        return TaskStatus.todo;
      case 'in_progress':
        return TaskStatus.inProgress;
      case 'done':
        return TaskStatus.done;
      case 'cancelled':
        return TaskStatus.cancelled;
      default:
        return TaskStatus.todo;
    }
  }

  String toJson() {
    switch (this) {
      case TaskStatus.todo:
        return 'todo';
      case TaskStatus.inProgress:
        return 'in_progress';
      case TaskStatus.done:
        return 'done';
      case TaskStatus.cancelled:
        return 'cancelled';
    }
  }
}

class Task {
  final int id;
  final String title;
  final Priority priority;
  final TaskStatus status;

  Task({
    required this.id,
    required this.title,
    required this.priority,
    required this.status,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as int,
      title: json['title'] as String,
      priority: Priority.fromJson(json['priority'] as String),
      status: TaskStatus.fromJson(json['status'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'priority': priority.toJson(),
        'status': status.toJson(),
      };
}
```

---

## Aufgabe 5: json_serializable

```dart
// product.dart
import 'package:json_annotation/json_annotation.dart';

part 'product.g.dart';

@JsonSerializable()
class Product {
  final int id;

  @JsonKey(name: 'name')
  final String name;

  @JsonKey(defaultValue: 0.0)
  final double price;

  final String category;

  @JsonKey(name: 'in_stock', defaultValue: false)
  final bool inStock;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.inStock,
  });

  factory Product.fromJson(Map<String, dynamic> json) =>
      _$ProductFromJson(json);

  Map<String, dynamic> toJson() => _$ProductToJson(this);
}
```

Nach `flutter pub run build_runner build` wird `product.g.dart` generiert.

---

## Aufgabe 6: Fehlerbehandlung

```dart
import 'dart:convert';

class JsonParseException implements Exception {
  final String message;
  final dynamic originalError;

  JsonParseException(this.message, [this.originalError]);

  @override
  String toString() => 'JsonParseException: $message';
}

T? safeParse<T>(
  String jsonString,
  T Function(Map<String, dynamic>) fromJson,
) {
  try {
    final decoded = jsonDecode(jsonString);

    if (decoded is! Map<String, dynamic>) {
      throw JsonParseException('Expected JSON object, got ${decoded.runtimeType}');
    }

    return fromJson(decoded);
  } on FormatException catch (e) {
    print('Invalid JSON format: $e');
    return null;
  } on TypeError catch (e) {
    print('Type error while parsing: $e');
    return null;
  } on JsonParseException catch (e) {
    print(e);
    return null;
  } catch (e) {
    print('Unexpected error: $e');
    return null;
  }
}

// Variante die Exception wirft
T parseOrThrow<T>(
  String jsonString,
  T Function(Map<String, dynamic>) fromJson,
) {
  try {
    final decoded = jsonDecode(jsonString);

    if (decoded is! Map<String, dynamic>) {
      throw JsonParseException('Expected JSON object');
    }

    return fromJson(decoded);
  } on FormatException catch (e) {
    throw JsonParseException('Invalid JSON format', e);
  } on TypeError catch (e) {
    throw JsonParseException('Missing or invalid field', e);
  }
}

// Tests
void main() {
  // Gültiges JSON
  final valid = '{"id": 1, "title": "Test", "author": "Max", "pages": 100, "published": true, "rating": 4.5}';
  final book = safeParse(valid, Book.fromJson);
  print(book);  // Book(...)

  // Ungültiges JSON
  final invalid = '{invalid json}';
  final result1 = safeParse(invalid, Book.fromJson);
  print(result1);  // null

  // Fehlende Felder
  final missing = '{"id": 1}';
  final result2 = safeParse(missing, Book.fromJson);
  print(result2);  // null

  // Falsche Typen
  final wrongType = '{"id": "not a number", "title": 123}';
  final result3 = safeParse(wrongType, Book.fromJson);
  print(result3);  // null
}
```

---

## Aufgabe 7: User API Integration

```dart
// models/address.dart
class Geo {
  final String lat;
  final String lng;

  Geo({required this.lat, required this.lng});

  factory Geo.fromJson(Map<String, dynamic> json) {
    return Geo(
      lat: json['lat'] as String,
      lng: json['lng'] as String,
    );
  }
}

class Address {
  final String street;
  final String suite;
  final String city;
  final String zipcode;
  final Geo geo;

  Address({
    required this.street,
    required this.suite,
    required this.city,
    required this.zipcode,
    required this.geo,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      street: json['street'] as String,
      suite: json['suite'] as String,
      city: json['city'] as String,
      zipcode: json['zipcode'] as String,
      geo: Geo.fromJson(json['geo'] as Map<String, dynamic>),
    );
  }

  String get fullAddress => '$street, $suite, $city $zipcode';
}

// models/company.dart
class Company {
  final String name;
  final String catchPhrase;
  final String bs;

  Company({
    required this.name,
    required this.catchPhrase,
    required this.bs,
  });

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      name: json['name'] as String,
      catchPhrase: json['catchPhrase'] as String,
      bs: json['bs'] as String,
    );
  }
}

// models/user.dart
class User {
  final int id;
  final String name;
  final String username;
  final String email;
  final Address address;
  final String phone;
  final String website;
  final Company company;

  User({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.address,
    required this.phone,
    required this.website,
    required this.company,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      address: Address.fromJson(json['address'] as Map<String, dynamic>),
      phone: json['phone'] as String,
      website: json['website'] as String,
      company: Company.fromJson(json['company'] as Map<String, dynamic>),
    );
  }
}

// services/user_service.dart
class UserService {
  static const baseUrl = 'https://jsonplaceholder.typicode.com';

  Future<List<User>> fetchUsers() async {
    final response = await http.get(Uri.parse('$baseUrl/users'));

    if (response.statusCode != 200) {
      throw Exception('Failed to load users');
    }

    final List<dynamic> jsonList = jsonDecode(response.body);
    return jsonList
        .map((json) => User.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}

// Widget
class UsersListPage extends StatefulWidget {
  @override
  State<UsersListPage> createState() => _UsersListPageState();
}

class _UsersListPageState extends State<UsersListPage> {
  late Future<List<User>> _usersFuture;

  @override
  void initState() {
    super.initState();
    _usersFuture = UserService().fetchUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Users')),
      body: FutureBuilder<List<User>>(
        future: _usersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final users = snapshot.data!;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                leading: CircleAvatar(child: Text(user.name[0])),
                title: Text(user.name),
                subtitle: Text('${user.email}\n${user.company.name}'),
                isThreeLine: true,
              );
            },
          );
        },
      ),
    );
  }
}
```
