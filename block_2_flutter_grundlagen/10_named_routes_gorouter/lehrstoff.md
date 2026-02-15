# Einheit 2.10: Named Routes & go_router

> **Dauer:** 2 Stunden | **Voraussetzungen:** Einheit 2.9

---

## 10.1 Named Routes (Flutter Standard)

```dart
MaterialApp(
  initialRoute: '/',
  routes: {
    '/': (context) => HomePage(),
    '/login': (context) => LoginPage(),
    '/settings': (context) => SettingsPage(),
    '/profile': (context) => ProfilePage(),
  },
)

// Navigation
Navigator.pushNamed(context, '/settings');

// Mit Argumenten
Navigator.pushNamed(
  context,
  '/profile',
  arguments: {'userId': 42},
);

// Argumente empfangen
class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map;
    final userId = args['userId'];
    return Scaffold(...);
  }
}
```

---

## 10.2 onGenerateRoute

```dart
MaterialApp(
  initialRoute: '/',
  onGenerateRoute: (settings) {
    // Dynamisches Routing
    if (settings.name == '/') {
      return MaterialPageRoute(builder: (_) => HomePage());
    }

    // Route mit Parameter: /user/123
    final uri = Uri.parse(settings.name!);
    if (uri.pathSegments.length == 2 && uri.pathSegments[0] == 'user') {
      final userId = int.parse(uri.pathSegments[1]);
      return MaterialPageRoute(
        builder: (_) => UserPage(userId: userId),
      );
    }

    // 404 Seite
    return MaterialPageRoute(builder: (_) => NotFoundPage());
  },
)

// Navigation
Navigator.pushNamed(context, '/user/42');
```

---

## 10.3 go_router Setup

```yaml
# pubspec.yaml
dependencies:
  go_router: ^13.0.0
```

```dart
import 'package:go_router/go_router.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => HomePage(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => LoginPage(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => SettingsPage(),
    ),
  ],
);

// App
MaterialApp.router(
  routerConfig: router,
)
```

---

## 10.4 go_router Navigation

```dart
// Navigation
context.go('/settings');        // Ersetzt Stack
context.push('/settings');      // Fügt hinzu
context.pop();                  // Zurück
context.replace('/home');       // Ersetzt aktuelle Route

// Mit GoRouter-Instanz
GoRouter.of(context).go('/settings');
```

---

## 10.5 Path Parameters

```dart
GoRoute(
  path: '/user/:id',
  builder: (context, state) {
    final userId = state.pathParameters['id']!;
    return UserPage(userId: int.parse(userId));
  },
),

GoRoute(
  path: '/product/:category/:id',
  builder: (context, state) {
    final category = state.pathParameters['category']!;
    final id = state.pathParameters['id']!;
    return ProductPage(category: category, id: id);
  },
),

// Navigation
context.go('/user/42');
context.go('/product/electronics/123');
```

---

## 10.6 Query Parameters

```dart
GoRoute(
  path: '/search',
  builder: (context, state) {
    final query = state.uri.queryParameters['q'] ?? '';
    final page = int.tryParse(state.uri.queryParameters['page'] ?? '1') ?? 1;
    return SearchPage(query: query, page: page);
  },
),

// Navigation
context.go('/search?q=flutter&page=2');

// Mit Uri
context.go(Uri(
  path: '/search',
  queryParameters: {'q': 'flutter', 'page': '2'},
).toString());
```

---

## 10.7 Nested Routes (ShellRoute)

```dart
final router = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) {
        return MainShell(child: child);
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => HomePage(),
        ),
        GoRoute(
          path: '/search',
          builder: (context, state) => SearchPage(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => ProfilePage(),
        ),
      ],
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => LoginPage(),
    ),
  ],
);

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _calculateIndex(GoRouterState.of(context).uri.path),
        onTap: (index) {
          switch (index) {
            case 0: context.go('/');
            case 1: context.go('/search');
            case 2: context.go('/profile');
          }
        },
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Suche'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }

  int _calculateIndex(String path) {
    if (path.startsWith('/search')) return 1;
    if (path.startsWith('/profile')) return 2;
    return 0;
  }
}
```

---

## 10.8 Redirect & Guards

```dart
final router = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    final isLoggedIn = AuthService.isLoggedIn;
    final isLoginRoute = state.matchedLocation == '/login';

    // Nicht eingeloggt und nicht auf Login-Seite
    if (!isLoggedIn && !isLoginRoute) {
      return '/login';
    }

    // Eingeloggt aber auf Login-Seite
    if (isLoggedIn && isLoginRoute) {
      return '/';
    }

    return null;  // Keine Umleitung
  },
  routes: [...],
);

// Pro Route
GoRoute(
  path: '/admin',
  redirect: (context, state) {
    if (!AuthService.isAdmin) {
      return '/unauthorized';
    }
    return null;
  },
  builder: (context, state) => AdminPage(),
),
```

---

## 10.9 Extra Data

```dart
// Komplexe Objekte übergeben
class Product {
  final int id;
  final String name;
  Product({required this.id, required this.name});
}

GoRoute(
  path: '/product/:id',
  builder: (context, state) {
    final product = state.extra as Product?;
    if (product != null) {
      return ProductPage(product: product);
    }
    // Fallback: ID aus URL laden
    final id = state.pathParameters['id']!;
    return ProductPage(productId: int.parse(id));
  },
),

// Navigation mit extra
context.go(
  '/product/42',
  extra: Product(id: 42, name: 'Laptop'),
);
```

---

## 10.10 Beispiel: Komplette App-Navigation

```dart
final router = GoRouter(
  initialLocation: '/',
  debugLogDiagnostics: true,
  redirect: (context, state) {
    // Auth-Check hier
    return null;
  },
  routes: [
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => HomePage(),
          routes: [
            GoRoute(
              path: 'product/:id',
              builder: (context, state) {
                final id = state.pathParameters['id']!;
                return ProductDetailPage(id: id);
              },
            ),
          ],
        ),
        GoRoute(
          path: '/cart',
          builder: (context, state) => CartPage(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => ProfilePage(),
          routes: [
            GoRoute(
              path: 'settings',
              builder: (context, state) => SettingsPage(),
            ),
            GoRoute(
              path: 'orders',
              builder: (context, state) => OrdersPage(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => LoginPage(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => OnboardingPage(),
    ),
  ],
  errorBuilder: (context, state) => ErrorPage(error: state.error),
);
```

