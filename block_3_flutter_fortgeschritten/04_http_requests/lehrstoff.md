# Einheit 3.4: HTTP Requests

## Lernziele

Nach dieser Einheit kannst du:
- Das `http` Package für Netzwerk-Requests verwenden
- GET, POST, PUT, DELETE Requests durchführen
- Headers und Query-Parameter setzen
- Timeouts und Fehlerbehandlung implementieren
- Response-Daten verarbeiten

---

## 1. Setup

### Installation

```yaml
# pubspec.yaml
dependencies:
  http: ^1.2.0
```

```bash
flutter pub get
```

### Import

```dart
import 'package:http/http.dart' as http;
```

Der `as http` Alias verhindert Namenskonflikte.

---

## 2. GET Requests

### Einfacher GET Request

```dart
Future<void> fetchData() async {
  final url = Uri.parse('https://jsonplaceholder.typicode.com/posts/1');

  try {
    final response = await http.get(url);

    if (response.statusCode == 200) {
      print('Success: ${response.body}');
    } else {
      print('Error: ${response.statusCode}');
    }
  } catch (e) {
    print('Network error: $e');
  }
}
```

### Response-Objekt

```dart
final response = await http.get(url);

// Wichtige Properties
response.statusCode;     // 200, 404, 500, etc.
response.body;           // Response als String
response.bodyBytes;      // Response als Bytes (für Bilder, etc.)
response.headers;        // Map<String, String>
response.contentLength;  // Länge in Bytes
response.isRedirect;     // true wenn Redirect
response.reasonPhrase;   // "OK", "Not Found", etc.
```

### Mit Query-Parametern

```dart
// Option 1: In URL einbauen
final url = Uri.parse(
  'https://api.example.com/search?query=flutter&page=1',
);

// Option 2: Uri.https mit queryParameters (empfohlen)
final url = Uri.https(
  'api.example.com',      // Host (ohne https://)
  '/search',              // Path
  {                       // Query Parameters
    'query': 'flutter',
    'page': '1',
    'sort': 'date',
  },
);

// Für HTTP (nicht HTTPS):
final url = Uri.http('localhost:8080', '/api/items', {'limit': '10'});
```

### Mit Headers

```dart
final response = await http.get(
  url,
  headers: {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
    'X-Custom-Header': 'value',
  },
);
```

---

## 3. POST Requests

### JSON senden

```dart
import 'dart:convert';

Future<void> createPost() async {
  final url = Uri.parse('https://jsonplaceholder.typicode.com/posts');

  final response = await http.post(
    url,
    headers: {
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode({
      'title': 'Mein Post',
      'body': 'Inhalt des Posts',
      'userId': 1,
    }),
  );

  if (response.statusCode == 201) {
    print('Created: ${response.body}');
  } else {
    throw Exception('Failed to create post: ${response.statusCode}');
  }
}
```

### Form Data senden

```dart
final response = await http.post(
  url,
  headers: {
    'Content-Type': 'application/x-www-form-urlencoded',
  },
  body: {
    'username': 'max',
    'password': 'secret',
  },
  // body wird automatisch URL-encoded
);
```

---

## 4. PUT und DELETE

### PUT (Update)

```dart
Future<void> updatePost(int id, String title) async {
  final url = Uri.parse('https://jsonplaceholder.typicode.com/posts/$id');

  final response = await http.put(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'id': id,
      'title': title,
      'body': 'Updated content',
      'userId': 1,
    }),
  );

  if (response.statusCode == 200) {
    print('Updated successfully');
  }
}
```

### PATCH (Partial Update)

```dart
final response = await http.patch(
  url,
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({
    'title': 'Nur Titel ändern',
  }),
);
```

### DELETE

```dart
Future<void> deletePost(int id) async {
  final url = Uri.parse('https://jsonplaceholder.typicode.com/posts/$id');

  final response = await http.delete(url);

  if (response.statusCode == 200 || response.statusCode == 204) {
    print('Deleted successfully');
  }
}
```

---

## 5. Timeouts

### Request-Timeout

```dart
try {
  final response = await http
      .get(url)
      .timeout(const Duration(seconds: 10));

  print(response.body);
} on TimeoutException {
  print('Request timed out');
}
```

### Mit http.Client für mehr Kontrolle

```dart
final client = http.Client();

try {
  final response = await client
      .get(url)
      .timeout(const Duration(seconds: 10));

  print(response.body);
} finally {
  client.close();  // Wichtig: Ressourcen freigeben!
}
```

---

## 6. Fehlerbehandlung

### Umfassende Error-Handling

```dart
import 'dart:async';
import 'dart:io';

Future<String> fetchData(String endpoint) async {
  final url = Uri.parse('https://api.example.com/$endpoint');

  try {
    final response = await http
        .get(url)
        .timeout(const Duration(seconds: 10));

    switch (response.statusCode) {
      case 200:
        return response.body;
      case 400:
        throw BadRequestException(response.body);
      case 401:
        throw UnauthorizedException();
      case 403:
        throw ForbiddenException();
      case 404:
        throw NotFoundException(endpoint);
      case 500:
        throw ServerException();
      default:
        throw HttpException(
          'Unexpected status code: ${response.statusCode}',
        );
    }
  } on SocketException {
    throw NoInternetException();
  } on TimeoutException {
    throw RequestTimeoutException();
  } on FormatException {
    throw InvalidResponseException();
  }
}

// Custom Exceptions
class BadRequestException implements Exception {
  final String message;
  BadRequestException(this.message);
}

class UnauthorizedException implements Exception {}

class ForbiddenException implements Exception {}

class NotFoundException implements Exception {
  final String resource;
  NotFoundException(this.resource);
}

class ServerException implements Exception {}

class NoInternetException implements Exception {}

class RequestTimeoutException implements Exception {}

class InvalidResponseException implements Exception {}
```

---

## 7. API Service Klasse

### Strukturierter Ansatz

```dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl;
  final http.Client _client;
  String? _authToken;

  ApiService({
    required this.baseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  void setAuthToken(String token) {
    _authToken = token;
  }

  void clearAuthToken() {
    _authToken = null;
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (_authToken != null) 'Authorization': 'Bearer $_authToken',
      };

  Future<dynamic> get(String endpoint,
      {Map<String, String>? queryParams}) async {
    final uri = Uri.parse('$baseUrl$endpoint').replace(
      queryParameters: queryParams,
    );

    final response = await _request(() => _client.get(uri, headers: _headers));
    return jsonDecode(response.body);
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    final uri = Uri.parse('$baseUrl$endpoint');

    final response = await _request(() => _client.post(
          uri,
          headers: _headers,
          body: jsonEncode(data),
        ));

    return jsonDecode(response.body);
  }

  Future<dynamic> put(String endpoint, Map<String, dynamic> data) async {
    final uri = Uri.parse('$baseUrl$endpoint');

    final response = await _request(() => _client.put(
          uri,
          headers: _headers,
          body: jsonEncode(data),
        ));

    return jsonDecode(response.body);
  }

  Future<void> delete(String endpoint) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    await _request(() => _client.delete(uri, headers: _headers));
  }

  Future<http.Response> _request(
    Future<http.Response> Function() request,
  ) async {
    try {
      final response = await request().timeout(
        const Duration(seconds: 30),
      );

      _checkResponse(response);
      return response;
    } on SocketException {
      throw ApiException('No internet connection');
    } on TimeoutException {
      throw ApiException('Request timed out');
    }
  }

  void _checkResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    final body = response.body.isNotEmpty
        ? jsonDecode(response.body)
        : {'message': 'Unknown error'};

    throw ApiException(
      body['message'] ?? 'Request failed',
      statusCode: response.statusCode,
    );
  }

  void dispose() {
    _client.close();
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}
```

### Verwendung

```dart
final api = ApiService(baseUrl: 'https://api.example.com');

// Auth setzen
api.setAuthToken('my-token');

// GET
final posts = await api.get('/posts', queryParams: {'limit': '10'});

// POST
final newPost = await api.post('/posts', {
  'title': 'Hello',
  'body': 'World',
});

// PUT
await api.put('/posts/1', {'title': 'Updated'});

// DELETE
await api.delete('/posts/1');

// Cleanup
api.dispose();
```

---

## 8. Internet-Verbindung prüfen

### Mit connectivity_plus Package

```yaml
dependencies:
  connectivity_plus: ^5.0.2
```

```dart
import 'package:connectivity_plus/connectivity_plus.dart';

Future<bool> hasInternetConnection() async {
  final connectivityResult = await Connectivity().checkConnectivity();
  return connectivityResult != ConnectivityResult.none;
}

// Stream für Verbindungsänderungen
Connectivity().onConnectivityChanged.listen((result) {
  if (result == ConnectivityResult.none) {
    print('Offline');
  } else {
    print('Online: $result');
  }
});
```

---

## 9. Android/iOS Konfiguration

### Android: Internet-Permission

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET"/>
    <!-- ... -->
</manifest>
```

### iOS: HTTP erlauben (falls nötig)

```xml
<!-- ios/Runner/Info.plist -->
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

**Hinweis:** Für Produktion besser nur spezifische Domains erlauben.

---

## Zusammenfassung

| Methode | HTTP Verb | Verwendung |
|---------|-----------|-----------|
| `http.get()` | GET | Daten abrufen |
| `http.post()` | POST | Neue Ressource erstellen |
| `http.put()` | PUT | Ressource komplett ersetzen |
| `http.patch()` | PATCH | Ressource teilweise aktualisieren |
| `http.delete()` | DELETE | Ressource löschen |

**Best Practices:**
1. Immer Timeouts setzen
2. Fehler sauber behandeln
3. `http.Client` für mehrere Requests verwenden
4. API-Logik in Service-Klasse kapseln
5. Internet-Verbindung prüfen vor Requests
