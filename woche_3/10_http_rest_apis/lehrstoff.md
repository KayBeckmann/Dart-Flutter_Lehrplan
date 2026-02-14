# Modul 10: HTTP, REST-APIs & JSON

## Lernziele

Nach diesem Modul kannst du:
- HTTP-Requests (GET, POST, PUT, DELETE) mit dem `http` Package senden
- JSON-Daten in Dart-Objekte umwandeln und zurueck
- Model-Klassen mit `fromJson` und `toJson` erstellen
- `FutureBuilder` und `StreamBuilder` fuer asynchrone UI verwenden
- Netzwerkfehler robust behandeln
- Das Repository Pattern fuer API-Zugriffe anwenden
- HTTP-Requests mit Provider kombinieren

---

## 1. HTTP-Grundlagen: Kurze Auffrischung

Als Webentwickler kennst du REST-APIs bereits aus JavaScript. Hier die Dart-Perspektive.

### REST in 30 Sekunden

| Methode | Zweck | Beispiel |
|---------|-------|---------|
| GET | Daten abrufen | Alle Benutzer laden |
| POST | Neue Daten erstellen | Benutzer anlegen |
| PUT | Daten komplett ersetzen | Benutzer aktualisieren |
| PATCH | Daten teilweise aendern | Nur den Namen aendern |
| DELETE | Daten loeschen | Benutzer entfernen |

> **Vergleich mit JavaScript:** In JS verwendest du `fetch()` oder `axios`. In Dart verwenden wir das `http` Package (vergleichbar mit `fetch()`) oder `dio` (vergleichbar mit `axios`).

---

## 2. Das http Package

### Installation

```yaml
# pubspec.yaml
dependencies:
  http: ^1.2.1
```

```bash
flutter pub get
```

### Import

```dart
import 'package:http/http.dart' as http;
```

**Warum `as http`?** Das Package wird als Namespace importiert, um Namenskonflikte zu vermeiden. Du greifst dann auf alles mit `http.get()`, `http.post()` etc. zu.

---

## 3. HTTP-Requests senden

### GET Request

```dart
import 'package:http/http.dart' as http;

Future<void> fetchUsers() async {
  final url = Uri.parse('https://jsonplaceholder.typicode.com/users');

  final response = await http.get(url);

  print('Status Code: ${response.statusCode}');  // 200
  print('Body: ${response.body}');                // JSON-String
  print('Headers: ${response.headers}');          // Map<String, String>
}
```

### POST Request

```dart
Future<void> createUser() async {
  final url = Uri.parse('https://jsonplaceholder.typicode.com/users');

  final response = await http.post(
    url,
    headers: {
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode({
      'name': 'Max Mustermann',
      'email': 'max@example.com',
      'username': 'maxm',
    }),
  );

  print('Status: ${response.statusCode}');  // 201 (Created)
  print('Body: ${response.body}');
}
```

### PUT Request

```dart
Future<void> updateUser(int id) async {
  final url = Uri.parse('https://jsonplaceholder.typicode.com/users/$id');

  final response = await http.put(
    url,
    headers: {'Content-Type': 'application/json; charset=UTF-8'},
    body: jsonEncode({
      'name': 'Max Mustermann (aktualisiert)',
      'email': 'max.neu@example.com',
      'username': 'maxm',
    }),
  );

  print('Status: ${response.statusCode}');  // 200
}
```

### DELETE Request

```dart
Future<void> deleteUser(int id) async {
  final url = Uri.parse('https://jsonplaceholder.typicode.com/users/$id');

  final response = await http.delete(url);

  print('Status: ${response.statusCode}');  // 200
}
```

### PATCH Request

```dart
Future<void> patchUser(int id) async {
  final url = Uri.parse('https://jsonplaceholder.typicode.com/users/$id');

  final response = await http.patch(
    url,
    headers: {'Content-Type': 'application/json; charset=UTF-8'},
    body: jsonEncode({
      'name': 'Nur der Name aendert sich',
    }),
  );

  print('Status: ${response.statusCode}');  // 200
}
```

---

## 4. Headers setzen

Headers sind Metadaten, die mit dem Request mitgesendet werden:

```dart
final response = await http.get(
  Uri.parse('https://api.example.com/protected'),
  headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Authorization': 'Bearer dein_token_hier',
    'X-Custom-Header': 'custom_value',
  },
);
```

### Haeufige Headers

| Header | Zweck |
|--------|-------|
| `Content-Type` | Format der gesendeten Daten |
| `Accept` | Gewuenschtes Antwortformat |
| `Authorization` | Authentifizierung (Bearer Token, Basic Auth) |
| `User-Agent` | Identifikation des Clients |

---

## 5. Response verarbeiten

Das `Response`-Objekt hat folgende wichtige Eigenschaften:

```dart
final response = await http.get(url);

// Status Code pruefen
if (response.statusCode == 200) {
  // Erfolg
  final body = response.body;        // String
  final bytes = response.bodyBytes;   // Uint8List (fuer Binaerdaten)
  final headers = response.headers;   // Map<String, String>
} else if (response.statusCode == 404) {
  print('Nicht gefunden');
} else if (response.statusCode == 401) {
  print('Nicht autorisiert');
} else if (response.statusCode >= 500) {
  print('Serverfehler: ${response.statusCode}');
} else {
  print('Unerwarteter Status: ${response.statusCode}');
}
```

### Status Code Bereiche

| Bereich | Bedeutung | Beispiele |
|---------|-----------|----------|
| 2xx | Erfolg | 200 OK, 201 Created, 204 No Content |
| 3xx | Umleitung | 301 Moved, 304 Not Modified |
| 4xx | Client-Fehler | 400 Bad Request, 401 Unauthorized, 404 Not Found |
| 5xx | Server-Fehler | 500 Internal Error, 503 Service Unavailable |

---

## 6. JSON: dart:convert

JSON (JavaScript Object Notation) ist das Standard-Datenformat fuer REST-APIs. In Dart verwendest du `dart:convert`:

```dart
import 'dart:convert';
```

### jsonDecode: JSON-String --> Dart-Objekt

```dart
// JSON-String zu Map
final jsonString = '{"name": "Max", "age": 25}';
final Map<String, dynamic> map = jsonDecode(jsonString);
print(map['name']);  // Max
print(map['age']);   // 25

// JSON-Array zu List
final jsonArray = '[{"id": 1}, {"id": 2}]';
final List<dynamic> list = jsonDecode(jsonArray);
print(list[0]['id']);  // 1
```

### jsonEncode: Dart-Objekt --> JSON-String

```dart
// Map zu JSON-String
final map = {'name': 'Max', 'age': 25, 'hobbies': ['Flutter', 'Dart']};
final jsonString = jsonEncode(map);
print(jsonString);
// {"name":"Max","age":25,"hobbies":["Flutter","Dart"]}
```

> **Vergleich mit JavaScript:** `jsonDecode()` entspricht `JSON.parse()`, `jsonEncode()` entspricht `JSON.stringify()`. Praktisch identisch.

---

## 7. Model-Klassen: Das Herzstrueck

Rohe `Map<String, dynamic>` zu verwenden ist fehleranfaellig. Besser: Eigene Klassen mit typsicheren Feldern.

### Einfache Model-Klasse

```dart
class User {
  final int id;
  final String name;
  final String email;
  final String username;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.username,
  });

  /// Factory-Konstruktor: JSON-Map --> User-Objekt
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      username: json['username'] as String,
    );
  }

  /// User-Objekt --> JSON-Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'username': username,
    };
  }

  @override
  String toString() => 'User(id: $id, name: $name, email: $email)';
}
```

### Verwendung mit HTTP

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

Future<List<User>> fetchUsers() async {
  final url = Uri.parse('https://jsonplaceholder.typicode.com/users');
  final response = await http.get(url);

  if (response.statusCode == 200) {
    final List<dynamic> jsonList = jsonDecode(response.body);
    return jsonList.map((json) => User.fromJson(json)).toList();
  } else {
    throw Exception('Fehler beim Laden der Benutzer: ${response.statusCode}');
  }
}

Future<User> createUser(User user) async {
  final url = Uri.parse('https://jsonplaceholder.typicode.com/users');
  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json; charset=UTF-8'},
    body: jsonEncode(user.toJson()),
  );

  if (response.statusCode == 201) {
    return User.fromJson(jsonDecode(response.body));
  } else {
    throw Exception('Fehler beim Erstellen: ${response.statusCode}');
  }
}
```

### Verschachtelte Model-Klassen

Oft hat die API verschachtelte Objekte:

```json
{
  "id": 1,
  "name": "Leanne Graham",
  "address": {
    "street": "Kulas Light",
    "city": "Gwenborough",
    "geo": {
      "lat": "-37.3159",
      "lng": "81.1496"
    }
  },
  "company": {
    "name": "Romaguera-Crona"
  }
}
```

```dart
class Geo {
  final String lat;
  final String lng;

  const Geo({required this.lat, required this.lng});

  factory Geo.fromJson(Map<String, dynamic> json) {
    return Geo(
      lat: json['lat'] as String,
      lng: json['lng'] as String,
    );
  }

  Map<String, dynamic> toJson() => {'lat': lat, 'lng': lng};
}

class Address {
  final String street;
  final String city;
  final Geo geo;

  const Address({
    required this.street,
    required this.city,
    required this.geo,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      street: json['street'] as String,
      city: json['city'] as String,
      geo: Geo.fromJson(json['geo'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {
    'street': street,
    'city': city,
    'geo': geo.toJson(),
  };
}

class Company {
  final String name;

  const Company({required this.name});

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(name: json['name'] as String);
  }

  Map<String, dynamic> toJson() => {'name': name};
}

class UserDetailed {
  final int id;
  final String name;
  final Address address;
  final Company company;

  const UserDetailed({
    required this.id,
    required this.name,
    required this.address,
    required this.company,
  });

  factory UserDetailed.fromJson(Map<String, dynamic> json) {
    return UserDetailed(
      id: json['id'] as int,
      name: json['name'] as String,
      address: Address.fromJson(json['address'] as Map<String, dynamic>),
      company: Company.fromJson(json['company'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'address': address.toJson(),
    'company': company.toJson(),
  };
}
```

### Umgang mit optionalen Feldern

```dart
class Post {
  final int id;
  final String title;
  final String body;
  final String? imageUrl;   // Kann null sein
  final List<String> tags;  // Kann leere Liste sein

  const Post({
    required this.id,
    required this.title,
    required this.body,
    this.imageUrl,
    this.tags = const [],
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] as int,
      title: json['title'] as String,
      body: json['body'] as String,
      imageUrl: json['imageUrl'] as String?,  // null wenn nicht vorhanden
      tags: (json['tags'] as List<dynamic>?)
              ?.map((t) => t as String)
              .toList() ??
          [],  // Leere Liste als Fallback
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    if (imageUrl != null) 'imageUrl': imageUrl,
    'tags': tags,
  };
}
```

---

## 8. FutureBuilder: Asynchrone Daten im UI

`FutureBuilder` baut sein Widget basierend auf dem Zustand eines `Future`:

```dart
class UserListPage extends StatelessWidget {
  const UserListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Benutzer')),
      body: FutureBuilder<List<User>>(
        future: fetchUsers(),  // Das Future
        builder: (context, snapshot) {
          // 1. Laden
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. Fehler
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Fehler: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Seite neu laden (einfachste Methode)
                      // Bessere Methode: mit Provider (siehe unten)
                    },
                    child: const Text('Erneut versuchen'),
                  ),
                ],
              ),
            );
          }

          // 3. Keine Daten
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Keine Benutzer gefunden'));
          }

          // 4. Daten anzeigen
          final users = snapshot.data!;
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                leading: CircleAvatar(child: Text(user.name[0])),
                title: Text(user.name),
                subtitle: Text(user.email),
              );
            },
          );
        },
      ),
    );
  }
}
```

### ConnectionState Werte

| State | Bedeutung |
|-------|-----------|
| `none` | Kein Future zugewiesen |
| `waiting` | Future laeuft noch |
| `active` | Bei Streams: Daten kommen |
| `done` | Future ist fertig (mit Daten oder Fehler) |

### Wichtiger Hinweis zu FutureBuilder

**Achtung:** Erstelle das Future NICHT direkt in `build()`! Sonst wird bei jedem Rebuild ein neuer HTTP-Request ausgeloest:

```dart
// FALSCH: Neuer Request bei jedem Build
class UserListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<User>>(
      future: fetchUsers(),  // SCHLECHT! Wird bei jedem Build aufgerufen
      builder: ...
    );
  }
}

// RICHTIG: Future einmal erstellen und speichern
class UserListPage extends StatefulWidget {
  @override
  State<UserListPage> createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  late final Future<List<User>> _usersFuture;

  @override
  void initState() {
    super.initState();
    _usersFuture = fetchUsers();  // Nur einmal
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<User>>(
      future: _usersFuture,  // Gespeichertes Future
      builder: ...
    );
  }
}
```

**Noch besser:** Verwende einen Provider (siehe Abschnitt 12).

---

## 9. StreamBuilder (kurz)

`StreamBuilder` ist das Aequivalent fuer Streams -- wenn die Daten sich laufend aendern:

```dart
StreamBuilder<List<Message>>(
  stream: chatService.getMessages(),  // Gibt einen Stream zurueck
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const CircularProgressIndicator();
    }

    if (snapshot.hasError) {
      return Text('Fehler: ${snapshot.error}');
    }

    final messages = snapshot.data ?? [];
    return ListView.builder(
      itemCount: messages.length,
      itemBuilder: (context, index) => MessageTile(messages[index]),
    );
  },
)
```

> **Wann StreamBuilder statt FutureBuilder?** StreamBuilder ist fuer kontinuierliche Daten (Chat, Live-Updates, WebSocket). FutureBuilder fuer einmalige Abfragen.

---

## 10. Error Handling: Robust gegen Netzwerkprobleme

### Verschiedene Fehlertypen

```dart
import 'dart:io';
import 'dart:async';

Future<List<User>> fetchUsersRobust() async {
  try {
    final url = Uri.parse('https://jsonplaceholder.typicode.com/users');

    final response = await http.get(url).timeout(
      const Duration(seconds: 10),
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((json) => User.fromJson(json)).toList();
    } else if (response.statusCode == 404) {
      throw ApiException('Ressource nicht gefunden', response.statusCode);
    } else if (response.statusCode == 401) {
      throw ApiException('Nicht autorisiert', response.statusCode);
    } else {
      throw ApiException(
        'Serverfehler: ${response.statusCode}',
        response.statusCode,
      );
    }
  } on SocketException {
    throw ApiException('Keine Internetverbindung', null);
  } on TimeoutException {
    throw ApiException('Zeitlimit ueberschritten', null);
  } on FormatException {
    throw ApiException('Ungueltige Antwort vom Server', null);
  }
}

// Eigene Exception-Klasse
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, this.statusCode);

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}
```

### Timeout setzen

```dart
// Timeout auf dem Request
final response = await http.get(url).timeout(
  const Duration(seconds: 10),
  onTimeout: () {
    // Optional: Eigene Response bei Timeout
    return http.Response('Timeout', 408);
  },
);
```

### Retry-Logik

```dart
Future<http.Response> fetchWithRetry(
  Uri url, {
  int maxRetries = 3,
  Duration delay = const Duration(seconds: 2),
}) async {
  int attempt = 0;

  while (true) {
    try {
      attempt++;
      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode >= 500 && attempt < maxRetries) {
        // Server-Fehler: Erneut versuchen
        await Future.delayed(delay * attempt);  // Exponential Backoff
        continue;
      }

      return response;
    } on SocketException {
      if (attempt >= maxRetries) rethrow;
      await Future.delayed(delay * attempt);
    } on TimeoutException {
      if (attempt >= maxRetries) rethrow;
      await Future.delayed(delay * attempt);
    }
  }
}
```

---

## 11. Das dio Package: Fortgeschrittene Alternative

`dio` ist ein maechtigeres HTTP-Package (vergleichbar mit `axios` in JavaScript):

```yaml
dependencies:
  dio: ^5.4.1
```

### Grundlegende Verwendung

```dart
import 'package:dio/dio.dart';

final dio = Dio(BaseOptions(
  baseUrl: 'https://jsonplaceholder.typicode.com',
  connectTimeout: const Duration(seconds: 10),
  receiveTimeout: const Duration(seconds: 10),
  headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  },
));

// GET
Future<List<User>> fetchUsers() async {
  final response = await dio.get('/users');
  // dio dekodiert JSON automatisch!
  final List<dynamic> data = response.data;
  return data.map((json) => User.fromJson(json)).toList();
}

// POST
Future<User> createUser(User user) async {
  final response = await dio.post('/users', data: user.toJson());
  return User.fromJson(response.data);
}
```

### Interceptors (Middleware)

```dart
dio.interceptors.add(InterceptorsWrapper(
  onRequest: (options, handler) {
    print('REQUEST: ${options.method} ${options.uri}');
    // Token hinzufuegen
    options.headers['Authorization'] = 'Bearer $token';
    handler.next(options);
  },
  onResponse: (response, handler) {
    print('RESPONSE: ${response.statusCode}');
    handler.next(response);
  },
  onError: (error, handler) {
    print('ERROR: ${error.message}');
    // Bei 401: Token refreshen und erneut versuchen
    if (error.response?.statusCode == 401) {
      // refreshToken() und Request wiederholen
    }
    handler.next(error);
  },
));
```

### Cancel Token (Request abbrechen)

```dart
final cancelToken = CancelToken();

// Request starten
dio.get('/users', cancelToken: cancelToken).then((response) {
  print(response.data);
}).catchError((error) {
  if (CancelToken.isCancel(error)) {
    print('Request abgebrochen');
  }
});

// Request abbrechen (z.B. wenn der User die Seite verlaesst)
cancelToken.cancel('Benutzer hat die Seite verlassen');
```

### Wann http, wann dio?

| Feature | http | dio |
|---------|------|-----|
| Einfache Requests | Ja | Ja |
| Interceptors | Nein | Ja |
| Cancel Tokens | Nein | Ja |
| Progress Tracking | Nein | Ja |
| FormData/Upload | Eingeschraenkt | Ja |
| Auto JSON-Decode | Nein | Ja |
| Groesse | Klein | Groesser |

**Empfehlung:** Starte mit `http`. Wenn du Interceptors oder Cancel Tokens brauchst, wechsle zu `dio`.

---

## 12. json_serializable: Automatische Serialisierung

Bei vielen Model-Klassen wird das manuelle Schreiben von `fromJson`/`toJson` muehsam. `json_serializable` generiert den Code automatisch.

### Setup

```yaml
# pubspec.yaml
dependencies:
  json_annotation: ^4.8.1

dev_dependencies:
  build_runner: ^2.4.8
  json_serializable: ^6.7.1
```

### Model-Klasse annotieren

```dart
import 'package:json_annotation/json_annotation.dart';

// Generierte Datei einbinden (existiert erst nach Code-Generierung)
part 'user.g.dart';

@JsonSerializable()
class User {
  final int id;
  final String name;
  final String email;

  @JsonKey(name: 'user_name')  // Falls JSON-Key anders heisst
  final String username;

  @JsonKey(defaultValue: false)
  final bool isActive;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.username,
    this.isActive = false,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);
}
```

### Code generieren

```bash
# Einmalig generieren
dart run build_runner build

# Kontinuierlich generieren (bei Aenderungen)
dart run build_runner watch

# Bei Konflikten: Alte Dateien ueberschreiben
dart run build_runner build --delete-conflicting-outputs
```

Das erzeugt eine Datei `user.g.dart` mit der generierten Implementierung.

### Verschachtelte Objekte

```dart
@JsonSerializable()
class Address {
  final String street;
  final String city;

  const Address({required this.street, required this.city});

  factory Address.fromJson(Map<String, dynamic> json) =>
      _$AddressFromJson(json);
  Map<String, dynamic> toJson() => _$AddressToJson(this);
}

@JsonSerializable()
class User {
  final int id;
  final String name;
  final Address address;  // Verschachteltes Objekt

  const User({
    required this.id,
    required this.name,
    required this.address,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);
}
```

---

## 13. Repository Pattern: API-Zugriff kapseln

Das Repository Pattern trennt die Datenzugriffs-Logik vom Rest der App:

```
┌──────────┐     ┌──────────────┐     ┌─────────┐
│  Widget   │────►│  Repository  │────►│   API   │
│  (View)   │     │ (Abstraktion)│     │ (http)  │
└──────────┘     └──────────────┘     └─────────┘
```

### Abstrakte Repository-Klasse (Interface)

```dart
abstract class UserRepository {
  Future<List<User>> getUsers();
  Future<User> getUserById(int id);
  Future<User> createUser(User user);
  Future<User> updateUser(User user);
  Future<void> deleteUser(int id);
  Future<List<Post>> getUserPosts(int userId);
}
```

### Konkrete Implementierung

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiUserRepository implements UserRepository {
  final http.Client _client;
  final String _baseUrl = 'https://jsonplaceholder.typicode.com';

  ApiUserRepository({http.Client? client})
      : _client = client ?? http.Client();

  @override
  Future<List<User>> getUsers() async {
    final response = await _client
        .get(Uri.parse('$_baseUrl/users'))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((json) => User.fromJson(json)).toList();
    }
    throw ApiException('Fehler beim Laden der Benutzer', response.statusCode);
  }

  @override
  Future<User> getUserById(int id) async {
    final response = await _client
        .get(Uri.parse('$_baseUrl/users/$id'))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    }
    throw ApiException('Benutzer nicht gefunden', response.statusCode);
  }

  @override
  Future<List<Post>> getUserPosts(int userId) async {
    final response = await _client
        .get(Uri.parse('$_baseUrl/posts?userId=$userId'))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((json) => Post.fromJson(json)).toList();
    }
    throw ApiException('Fehler beim Laden der Posts', response.statusCode);
  }

  @override
  Future<User> createUser(User user) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/users'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode(user.toJson()),
    );

    if (response.statusCode == 201) {
      return User.fromJson(jsonDecode(response.body));
    }
    throw ApiException('Fehler beim Erstellen', response.statusCode);
  }

  @override
  Future<User> updateUser(User user) async {
    final response = await _client.put(
      Uri.parse('$_baseUrl/users/${user.id}'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode(user.toJson()),
    );

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    }
    throw ApiException('Fehler beim Aktualisieren', response.statusCode);
  }

  @override
  Future<void> deleteUser(int id) async {
    final response = await _client.delete(Uri.parse('$_baseUrl/users/$id'));

    if (response.statusCode != 200) {
      throw ApiException('Fehler beim Loeschen', response.statusCode);
    }
  }

  /// Client freigeben
  void dispose() {
    _client.close();
  }
}
```

### Vorteile des Repository Patterns

1. **Testbarkeit:** Du kannst ein `MockUserRepository` erstellen
2. **Austauschbarkeit:** API-Backend kann leicht gewechselt werden
3. **Saubere Trennung:** Widgets wissen nichts ueber HTTP
4. **Wiederverwendbarkeit:** Dasselbe Repository fuer mehrere Screens

---

## 14. Zusammenspiel mit Provider

Hier kommt alles zusammen -- Repository + Provider + UI:

### ViewModel mit Repository

```dart
class UserViewModel extends ChangeNotifier {
  final UserRepository _repository;

  List<User> _users = [];
  bool _isLoading = false;
  String? _error;

  UserViewModel({required UserRepository repository})
      : _repository = repository;

  List<User> get users => List.unmodifiable(_users);
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadUsers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _users = await _repository.getUsers();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await loadUsers();
  }
}
```

### Setup in main.dart

```dart
void main() {
  final userRepository = ApiUserRepository();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => UserViewModel(repository: userRepository)
            ..loadUsers(),  // Cascade: Sofort laden
        ),
      ],
      child: const MyApp(),
    ),
  );
}
```

### UI mit Provider

```dart
class UserListScreen extends StatelessWidget {
  const UserListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Benutzer')),
      body: Consumer<UserViewModel>(
        builder: (context, viewModel, _) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(viewModel.error!),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => context.read<UserViewModel>().loadUsers(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Erneut versuchen'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => context.read<UserViewModel>().refresh(),
            child: ListView.builder(
              itemCount: viewModel.users.length,
              itemBuilder: (context, index) {
                final user = viewModel.users[index];
                return ListTile(
                  leading: CircleAvatar(child: Text(user.name[0])),
                  title: Text(user.name),
                  subtitle: Text(user.email),
                  onTap: () {
                    // Navigation zur Detail-Seite
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
```

---

## 15. Vergleich: fetch() in JavaScript vs http in Dart

| JavaScript (fetch) | Dart (http) |
|-------------------|-------------|
| `const res = await fetch(url)` | `final res = await http.get(Uri.parse(url))` |
| `const data = await res.json()` | `final data = jsonDecode(res.body)` |
| `res.ok` | `res.statusCode == 200` |
| `res.status` | `res.statusCode` |
| `JSON.stringify(obj)` | `jsonEncode(obj)` |
| `JSON.parse(str)` | `jsonDecode(str)` |
| Headers-Objekt | Map<String, String> |

### JavaScript:

```javascript
const response = await fetch('https://api.example.com/users', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ name: 'Max' }),
});
const data = await response.json();
```

### Dart:

```dart
final response = await http.post(
  Uri.parse('https://api.example.com/users'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({'name': 'Max'}),
);
final data = jsonDecode(response.body);
```

Praktisch identisch -- die groessten Unterschiede sind:
- Dart: `Uri.parse()` noetig
- Dart: Body muss manuell als String kodiert werden
- Dart: Response muss manuell dekodiert werden (kein `.json()`)

---

## 16. Praxis: JSONPlaceholder als Test-API

[JSONPlaceholder](https://jsonplaceholder.typicode.com) ist eine kostenlose, oeffentliche API zum Testen:

| Endpunkt | Beschreibung |
|----------|-------------|
| `/users` | 10 Benutzer |
| `/posts` | 100 Blog-Posts |
| `/comments` | 500 Kommentare |
| `/albums` | 100 Alben |
| `/photos` | 5000 Fotos |
| `/todos` | 200 Todos |

### Nuetzliche Endpunkte fuer die Uebung

```
GET    /users           --> Alle Benutzer
GET    /users/1         --> Benutzer mit ID 1
GET    /posts?userId=1  --> Alle Posts von Benutzer 1
POST   /users           --> Neuen Benutzer erstellen (simuliert)
PUT    /users/1         --> Benutzer 1 aktualisieren (simuliert)
DELETE /users/1         --> Benutzer 1 loeschen (simuliert)
```

**Hinweis:** POST/PUT/DELETE aendern die Daten nicht wirklich auf dem Server, aber du bekommst eine korrekte Response zurueck.

---

## Zusammenfassung

```
HTTP-Request senden:
  http.get/post/put/delete(Uri.parse(url))
  --> Response mit statusCode und body

JSON verarbeiten:
  jsonDecode(string)  -->  Map/List
  jsonEncode(object)  -->  String

Model-Klassen:
  fromJson(Map)  -->  Typsicheres Objekt
  toJson()       -->  Map fuer die API

Asynchrone UI:
  FutureBuilder  -->  Einmalige Daten (API-Call)
  StreamBuilder  -->  Kontinuierliche Daten (WebSocket, Stream)

Architektur:
  Repository  -->  Kapselt API-Zugriffe
  ViewModel   -->  Verwaltet State + ruft Repository auf
  View        -->  Zeigt Daten an mit Consumer/watch

Error Handling:
  try/catch   -->  SocketException, TimeoutException, FormatException
  statusCode  -->  200, 404, 401, 500, etc.
```
