# Einheit 3.3: Provider Advanced

## Lernziele

Nach dieser Einheit kannst du:
- `Selector` für granulare Rebuilds verwenden
- Mehrere Provider mit `MultiProvider` kombinieren
- Abhängigkeiten zwischen Providern mit `ProxyProvider` modellieren
- `FutureProvider` für asynchrone Initialisierung nutzen
- Riverpod als moderne Alternative einordnen

---

## 1. Selector: Granulare Rebuilds

`Selector` rebuildet nur wenn sich ein bestimmter Wert ändert.

### Problem ohne Selector

```dart
class UserProfile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Rebuildet bei JEDER Änderung am User (Name, Email, Avatar, etc.)
    final user = context.watch<UserNotifier>();

    return Text(user.name);  // Braucht nur den Namen!
  }
}
```

### Lösung mit Selector

```dart
class UserProfile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Rebuildet NUR wenn sich der Name ändert
    final name = context.select<UserNotifier, String>(
      (notifier) => notifier.name,
    );

    return Text(name);
  }
}
```

### Selector Widget-Variante

```dart
Selector<UserNotifier, String>(
  selector: (_, notifier) => notifier.name,
  builder: (context, name, child) {
    return Text(name);
  },
  // child wird NICHT rebuilt
  child: const Icon(Icons.person),
);
```

### Mehrere Werte selektieren

```dart
// Mit einem Record
final (name, email) = context.select<UserNotifier, (String, String)>(
  (notifier) => (notifier.name, notifier.email),
);

// Oder ein eigenes Objekt
class UserDisplayData {
  final String name;
  final String email;
  UserDisplayData(this.name, this.email);

  @override
  bool operator ==(Object other) =>
      other is UserDisplayData &&
      name == other.name &&
      email == other.email;

  @override
  int get hashCode => Object.hash(name, email);
}

final displayData = context.select<UserNotifier, UserDisplayData>(
  (n) => UserDisplayData(n.name, n.email),
);
```

---

## 2. MultiProvider

Kombiniert mehrere Provider sauber ohne Verschachtelung.

### Ohne MultiProvider (tief verschachtelt)

```dart
// ❌ Schwer lesbar
ChangeNotifierProvider(
  create: (_) => AuthNotifier(),
  child: ChangeNotifierProvider(
    create: (_) => CartNotifier(),
    child: ChangeNotifierProvider(
      create: (_) => SettingsNotifier(),
      child: MyApp(),
    ),
  ),
);
```

### Mit MultiProvider

```dart
// ✅ Flache, lesbare Struktur
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => AuthNotifier()),
    ChangeNotifierProvider(create: (_) => CartNotifier()),
    ChangeNotifierProvider(create: (_) => SettingsNotifier()),
  ],
  child: MyApp(),
);
```

### Verschiedene Provider-Typen mischen

```dart
MultiProvider(
  providers: [
    // ChangeNotifier
    ChangeNotifierProvider(create: (_) => AuthNotifier()),

    // Einfacher Wert
    Provider(create: (_) => ApiService()),

    // Stream
    StreamProvider(
      create: (_) => FirebaseAuth.instance.authStateChanges(),
      initialData: null,
    ),

    // Future
    FutureProvider(
      create: (_) => loadConfig(),
      initialData: Config.defaultConfig,
    ),
  ],
  child: MyApp(),
);
```

---

## 3. ProxyProvider: Abhängigkeiten zwischen Providern

`ProxyProvider` erstellt einen Provider, der von anderen Providern abhängt.

### Szenario

```
AuthNotifier (User-Session)
       ↓
   UserService (API-Calls mit Auth-Token)
```

### Implementierung

```dart
MultiProvider(
  providers: [
    // 1. Auth Provider zuerst
    ChangeNotifierProvider(create: (_) => AuthNotifier()),

    // 2. UserService hängt von Auth ab
    ProxyProvider<AuthNotifier, UserService>(
      update: (_, auth, previousService) {
        return UserService(authToken: auth.token);
      },
    ),
  ],
  child: MyApp(),
);

// UserService
class UserService {
  final String? authToken;

  UserService({this.authToken});

  Future<User> fetchUser(String id) async {
    final response = await http.get(
      Uri.parse('https://api.example.com/users/$id'),
      headers: {'Authorization': 'Bearer $authToken'},
    );
    return User.fromJson(jsonDecode(response.body));
  }
}
```

### ProxyProvider mit mehreren Abhängigkeiten

```dart
// ProxyProvider2 für 2 Abhängigkeiten
ProxyProvider2<AuthNotifier, SettingsNotifier, ApiService>(
  update: (_, auth, settings, __) {
    return ApiService(
      token: auth.token,
      baseUrl: settings.apiBaseUrl,
    );
  },
);

// Es gibt ProxyProvider0 bis ProxyProvider6
```

### ChangeNotifierProxyProvider

Wenn der abhängige Provider selbst ein `ChangeNotifier` ist:

```dart
ChangeNotifierProxyProvider<AuthNotifier, UserProfileNotifier>(
  create: (_) => UserProfileNotifier(),
  update: (_, auth, profileNotifier) {
    // Update den bestehenden Notifier
    return profileNotifier!..updateAuth(auth.token);
  },
);
```

---

## 4. FutureProvider

Für asynchrone Initialisierung.

```dart
FutureProvider<Config>(
  create: (_) async {
    // Lade Konfiguration beim App-Start
    final response = await http.get(Uri.parse('https://api.example.com/config'));
    return Config.fromJson(jsonDecode(response.body));
  },
  initialData: Config.defaultConfig,  // Während des Ladens
  child: MyApp(),
);

// Verwendung
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final config = context.watch<Config>();
    return Text('API: ${config.apiUrl}');
  }
}
```

### Mit Loading/Error Handling

```dart
FutureProvider<AsyncValue<Config>>(
  create: (_) async {
    try {
      final config = await loadConfig();
      return AsyncValue.data(config);
    } catch (e) {
      return AsyncValue.error(e);
    }
  },
  initialData: AsyncValue.loading(),
  child: MyApp(),
);

// AsyncValue selbst definieren (oder Riverpod verwenden)
sealed class AsyncValue<T> {}
class AsyncLoading<T> extends AsyncValue<T> {}
class AsyncData<T> extends AsyncValue<T> {
  final T data;
  AsyncData(this.data);
}
class AsyncError<T> extends AsyncValue<T> {
  final Object error;
  AsyncError(this.error);
}
```

---

## 5. StreamProvider

Für reaktive Datenquellen.

```dart
StreamProvider<User?>(
  create: (_) => FirebaseAuth.instance.authStateChanges(),
  initialData: null,
  child: MyApp(),
);

// Verwendung
class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = context.watch<User?>();

    if (user == null) {
      return LoginPage();
    }
    return HomePage();
  }
}
```

---

## 6. Provider.value

Für bereits existierende Instanzen (nicht create).

```dart
// ⚠️ Achtung: dispose() wird NICHT aufgerufen!
Provider.value(
  value: existingService,
  child: MyWidget(),
);

// Sinnvoll z.B. für Route-Parameter
class DetailPage extends StatelessWidget {
  final Product product;

  DetailPage({required this.product});

  @override
  Widget build(BuildContext context) {
    return Provider.value(
      value: product,
      child: ProductDetails(),
    );
  }
}
```

---

## 7. Einführung in Riverpod

Riverpod ist die "nächste Generation" von Provider, vom selben Autor.

### Hauptunterschiede

| Feature | Provider | Riverpod |
|---------|----------|----------|
| BuildContext nötig | Ja | Nein |
| Compile-Time Safety | Teilweise | Voll |
| Testing | Umständlich | Einfach |
| Auto-dispose | Manuell | Automatisch |
| Provider außerhalb von Widgets | Schwierig | Einfach |

### Riverpod Grundkonzept

```dart
// Provider-Definition (global)
final counterProvider = StateNotifierProvider<CounterNotifier, int>((ref) {
  return CounterNotifier();
});

class CounterNotifier extends StateNotifier<int> {
  CounterNotifier() : super(0);

  void increment() => state++;
}

// Verwendung
class CounterWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(counterProvider);

    return Column(
      children: [
        Text('Count: $count'),
        ElevatedButton(
          onPressed: () => ref.read(counterProvider.notifier).increment(),
          child: Text('Increment'),
        ),
      ],
    );
  }
}
```

### Wann Riverpod statt Provider?

- **Provider:** Einfachere Apps, schneller Einstieg
- **Riverpod:** Komplexere Apps, bessere Testbarkeit, keine BuildContext-Abhängigkeit

---

## 8. Best Practices

### Provider-Organisation

```dart
// providers.dart - Zentrale Provider-Definition
class Providers {
  static List<SingleChildWidget> get all => [
    ChangeNotifierProvider(create: (_) => AuthNotifier()),
    ChangeNotifierProvider(create: (_) => ThemeNotifier()),
    ProxyProvider<AuthNotifier, ApiService>(
      update: (_, auth, __) => ApiService(auth.token),
    ),
  ];
}

// main.dart
void main() {
  runApp(
    MultiProvider(
      providers: Providers.all,
      child: MyApp(),
    ),
  );
}
```

### Scope richtig setzen

```dart
// Global (App-weiter State)
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => AuthNotifier()),
  ],
  child: MaterialApp(...),
);

// Lokal (Seiten-spezifischer State)
class ProductPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProductDetailNotifier(),
      child: ProductContent(),
    );
  }
}
```

### Selector vs Watch Entscheidung

```dart
// Verwende watch() wenn:
// - Du alle/die meisten Properties brauchst
// - Der Notifier selten Updates hat

// Verwende select() wenn:
// - Du nur 1-2 Properties brauchst
// - Der Notifier häufig Updates hat
// - Performance kritisch ist
```

---

## Zusammenfassung

| Konzept | Verwendung |
|---------|-----------|
| `Selector` | Rebuild nur bei bestimmten Änderungen |
| `MultiProvider` | Mehrere Provider kombinieren |
| `ProxyProvider` | Provider mit Abhängigkeiten |
| `FutureProvider` | Asynchrone Initialisierung |
| `StreamProvider` | Reaktive Datenquellen |
| `Provider.value` | Bestehende Instanzen bereitstellen |

**Entscheidungshilfe:**
- Einfache App → Provider reicht
- Komplexe Dependencies → ProxyProvider
- Compile-Time Safety wichtig → Riverpod
- Team-Projekt → Riverpod oder Bloc
