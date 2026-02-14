# Modul 10: Uebung -- Benutzerverzeichnis-App

## Aufgabenstellung

Baue eine **Benutzerverzeichnis-App**, die Daten von der JSONPlaceholder API laedt und anzeigt. Die App demonstriert HTTP-Requests, JSON-Serialisierung, das Repository Pattern und die Kombination mit Provider.

---

## Anforderungen

### 1. Datenmodelle

Erstelle Model-Klassen fuer:

**User:**
```
- id (int)
- name (String)
- username (String)
- email (String)
- phone (String)
- website (String)
- company (Company)   --> verschachteltes Objekt
- address (Address)   --> verschachteltes Objekt
```

**Company:**
```
- name (String)
- catchPhrase (String)
```

**Address:**
```
- street (String)
- suite (String)
- city (String)
- zipcode (String)
```

**Post:**
```
- userId (int)
- id (int)
- title (String)
- body (String)
```

Alle Klassen muessen `fromJson()` Factory-Konstruktoren haben.

### 2. UserRepository

Erstelle eine Repository-Klasse, die die API-Zugriffe kapselt:

- `getUsers()` --> Laedt alle Benutzer von `https://jsonplaceholder.typicode.com/users`
- `getUserById(int id)` --> Laedt einen einzelnen Benutzer
- `getUserPosts(int userId)` --> Laedt alle Posts eines Benutzers von `https://jsonplaceholder.typicode.com/posts?userId={userId}`
- Fehlerbehandlung: SocketException, TimeoutException, HTTP-Fehler
- Timeout: 10 Sekunden

### 3. UserViewModel (ChangeNotifier)

Erstelle einen Provider, der das Repository nutzt:

- `loadUsers()` -- Laedt die Benutzerliste
- `refreshUsers()` -- Laedt die Liste neu (fuer Pull-to-Refresh)
- State-Felder: `users`, `isLoading`, `error`

### 4. Screens

#### a) Benutzerliste (Hauptscreen)
- Zeige alle Benutzer in einer ListView an
- Jeder Eintrag zeigt: Name, E-Mail, Firmenname
- CircleAvatar mit dem ersten Buchstaben des Namens
- Pull-to-Refresh (RefreshIndicator)
- Ladezustand: CircularProgressIndicator
- Fehlerzustand: Fehlermeldung + Retry-Button
- Leer-Zustand: Hinweistext
- Tippen auf einen Benutzer oeffnet die Detail-Seite

#### b) Benutzer-Detail-Seite
- Zeige alle Informationen des Benutzers an (Name, Username, E-Mail, Telefon, Website, Firma, Adresse)
- Darunter: Liste der Posts des Benutzers
- Die Posts werden beim Oeffnen der Seite geladen (zweiter API-Call)
- Eigener Ladezustand fuer die Posts
- Fehlerbehandlung mit Retry fuer die Posts

### 5. Provider Setup

- `MultiProvider` in main.dart
- `UserRepository` als Provider bereitstellen (oder direkt im ViewModel injizieren)
- `UserViewModel` als ChangeNotifierProvider

### 6. Fehlerbehandlung

- Netzwerkfehler (kein Internet)
- Timeout (Server antwortet nicht)
- HTTP-Fehler (404, 500, etc.)
- JSON-Parsing-Fehler
- Jeder Fehlerzustand soll dem Benutzer verstaendlich angezeigt werden
- Jeder Fehlerzustand soll einen "Erneut versuchen"-Button haben

---

## API-Endpunkte

Verwende die JSONPlaceholder API:

| Endpunkt | Methode | Beschreibung |
|----------|---------|-------------|
| `https://jsonplaceholder.typicode.com/users` | GET | Alle Benutzer |
| `https://jsonplaceholder.typicode.com/users/{id}` | GET | Einzelner Benutzer |
| `https://jsonplaceholder.typicode.com/posts?userId={id}` | GET | Posts eines Benutzers |

---

## Projektstruktur

```
lib/
├── main.dart
├── models/
│   ├── user.dart
│   └── post.dart
├── repositories/
│   └── user_repository.dart
├── viewmodels/
│   └── user_viewmodel.dart
├── screens/
│   ├── user_list_screen.dart
│   └── user_detail_screen.dart
└── widgets/
    ├── user_card.dart
    ├── post_tile.dart
    └── error_view.dart
```

---

## Bonusaufgaben

1. **Suchfunktion:** Fuege eine Suchleiste hinzu, die die Benutzerliste lokal filtert (nach Name oder E-Mail)
2. **Favoriten:** Markiere Benutzer als Favoriten (gespeichert im Provider, nicht persistent)
3. **Offline-Hinweis:** Zeige einen Banner, wenn keine Internetverbindung besteht
4. **Animierter Uebergang:** Nutze eine Hero-Animation fuer den CircleAvatar zwischen Liste und Detail-Seite

---

## Hinweise

- Starte mit den Model-Klassen und teste sie mit einem einfachen `print()`
- Baue dann das Repository und teste es isoliert
- Verbinde Repository und ViewModel
- Baue die UI Schritt fuer Schritt auf
- Teste die Fehlerbehandlung, indem du den Flugmodus aktivierst oder eine falsche URL verwendest
- Verwende `RefreshIndicator` fuer Pull-to-Refresh (muss ein scrollbares Widget als Kind haben)
- Die JSONPlaceholder API gibt immer dieselben Daten zurueck -- das ist normal

---

## Erwartetes Verhalten

1. App startet und zeigt Ladeanimation
2. Benutzerliste erscheint nach dem Laden
3. Pull-to-Refresh laedt die Liste neu
4. Tippen auf einen Benutzer oeffnet die Detail-Seite
5. Detail-Seite zeigt Benutzerinfos und laedt Posts
6. Bei Netzwerkfehler: Fehlermeldung + Retry-Button
7. Retry-Button laedt die Daten erneut
