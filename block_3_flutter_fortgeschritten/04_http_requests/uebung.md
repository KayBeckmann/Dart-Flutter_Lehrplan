# Übung 3.4: HTTP Requests

## Ziel

Eine App erstellen, die Daten von einer REST API abruft und anzeigt.

---

## Aufgabe 1: Setup & GET Request (20 min)

1. Erstelle ein neues Flutter-Projekt
2. Füge das `http` Package hinzu
3. Erstelle eine einfache Funktion, die Posts von JSONPlaceholder abruft:

```dart
// https://jsonplaceholder.typicode.com/posts
```

4. Zeige die Response im Terminal an
5. Behandle mögliche Fehler

**Tipp:** Vergiss nicht die Internet-Permission in `AndroidManifest.xml`!

---

## Aufgabe 2: API Service Klasse (25 min)

Erstelle eine `PostService`-Klasse mit folgenden Methoden:

```dart
class PostService {
  static const baseUrl = 'https://jsonplaceholder.typicode.com';

  // Alle Posts abrufen
  Future<List<Post>> fetchPosts() async { ... }

  // Einzelnen Post abrufen
  Future<Post> fetchPost(int id) async { ... }

  // Neuen Post erstellen
  Future<Post> createPost(String title, String body, int userId) async { ... }

  // Post aktualisieren
  Future<Post> updatePost(int id, String title, String body) async { ... }

  // Post löschen
  Future<void> deletePost(int id) async { ... }
}
```

Das `Post`-Modell:

```dart
class Post {
  final int id;
  final int userId;
  final String title;
  final String body;

  Post({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
  });

  // fromJson und toJson implementieren
}
```

---

## Aufgabe 3: Posts anzeigen (25 min)

Erstelle eine `PostsPage`, die alle Posts anzeigt:

1. Zeige einen Loading-Indicator während des Ladens
2. Zeige eine Fehlermeldung bei Problemen
3. Zeige die Posts in einer ListView
4. Implementiere Pull-to-Refresh

```
┌─────────────────────────────────┐
│ Posts               [Refresh]  │
├─────────────────────────────────┤
│ ┌─────────────────────────────┐ │
│ │ Post Title 1                │ │
│ │ Post body excerpt...        │ │
│ └─────────────────────────────┘ │
│ ┌─────────────────────────────┐ │
│ │ Post Title 2                │ │
│ │ Post body excerpt...        │ │
│ └─────────────────────────────┘ │
│ ...                             │
└─────────────────────────────────┘
```

---

## Aufgabe 4: Post-Details & CRUD (30 min)

Erweitere die App:

1. **Detail-Ansicht:** Tippe auf einen Post → zeige Details
2. **Erstellen:** FAB → Dialog zum Erstellen eines neuen Posts
3. **Löschen:** Swipe-to-Delete auf Posts
4. **Aktualisieren:** Edit-Button in der Detail-Ansicht

**Hinweis:** JSONPlaceholder simuliert nur die Operationen - die Daten werden nicht wirklich gespeichert.

---

## Aufgabe 5: Error Handling (20 min)

Implementiere robuste Fehlerbehandlung:

1. **Timeout:** Request bricht nach 10 Sekunden ab
2. **Keine Verbindung:** Zeige "Keine Internetverbindung"
3. **Server-Fehler:** Zeige "Server nicht erreichbar"
4. **Retry-Button:** Ermögliche erneuten Versuch

```dart
// Custom Exceptions
class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);
}

class ServerException implements Exception {
  final int statusCode;
  ServerException(this.statusCode);
}
```

---

## Aufgabe 6: Verständnisfragen

1. Was ist der Unterschied zwischen `Uri.parse()` und `Uri.https()`?

2. Warum sollte man `http.Client()` verwenden statt direkt `http.get()`?

3. Was bedeutet der Statuscode 201 vs 200?

4. Warum wird `as http` beim Import verwendet?

5. Was passiert, wenn man `client.close()` nicht aufruft?

---

## Bonus: User-Posts laden

Erweitere die App um eine User-Ansicht:

1. Lade User von `https://jsonplaceholder.typicode.com/users`
2. Zeige eine User-Liste
3. Tippe auf User → zeige nur Posts dieses Users
4. Nutze Query-Parameter: `/posts?userId=1`

```dart
class User {
  final int id;
  final String name;
  final String email;
  final String username;

  // ...
}
```

---

## Abgabe-Checkliste

- [ ] http Package installiert
- [ ] GET Request funktioniert
- [ ] PostService mit allen CRUD-Methoden
- [ ] Posts werden in ListView angezeigt
- [ ] Loading-State wird angezeigt
- [ ] Error-State wird angezeigt
- [ ] Pull-to-Refresh funktioniert
- [ ] Timeout implementiert
- [ ] Verständnisfragen beantwortet
