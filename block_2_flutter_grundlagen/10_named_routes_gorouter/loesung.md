# Lösung 2.10: Named Routes & go_router

---

## Aufgabe 1

```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/',
      routes: {
        '/': (context) => HomePage(),
        '/about': (context) => AboutPage(),
        '/contact': (context) => ContactPage(),
      },
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Home')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Willkommen!', style: TextStyle(fontSize: 24)),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/about'),
              child: Text('Über uns'),
            ),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/contact'),
              child: Text('Kontakt'),
            ),
          ],
        ),
      ),
    );
  }
}

class AboutPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Über uns')),
      body: Center(child: Text('Über uns Seite')),
    );
  }
}

class ContactPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Kontakt')),
      body: Center(child: Text('Kontakt Seite')),
    );
  }
}
```

---

## Aufgabe 2

```dart
import 'package:go_router/go_router.dart';

class Post {
  final int id;
  final String title;
  final String category;
  final String content;

  Post({
    required this.id,
    required this.title,
    required this.category,
    required this.content,
  });
}

final posts = [
  Post(id: 1, title: 'Flutter Basics', category: 'flutter', content: '...'),
  Post(id: 2, title: 'Dart Tips', category: 'dart', content: '...'),
  Post(id: 3, title: 'State Management', category: 'flutter', content: '...'),
];

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => PostListPage(),
    ),
    GoRoute(
      path: '/post/:id',
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return PostDetailPage(postId: id);
      },
    ),
    GoRoute(
      path: '/category/:name',
      builder: (context, state) {
        final name = state.pathParameters['name']!;
        return CategoryPage(category: name);
      },
    ),
    GoRoute(
      path: '/search',
      builder: (context, state) {
        final query = state.uri.queryParameters['q'] ?? '';
        return SearchPage(query: query);
      },
    ),
  ],
);

class BlogApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(routerConfig: router);
  }
}

class PostListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Blog'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () => context.go('/search?q='),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: posts.length,
        itemBuilder: (context, index) {
          final post = posts[index];
          return ListTile(
            title: Text(post.title),
            subtitle: GestureDetector(
              onTap: () => context.go('/category/${post.category}'),
              child: Text(post.category, style: TextStyle(color: Colors.blue)),
            ),
            onTap: () => context.go('/post/${post.id}'),
          );
        },
      ),
    );
  }
}

class PostDetailPage extends StatelessWidget {
  final int postId;
  const PostDetailPage({required this.postId});

  @override
  Widget build(BuildContext context) {
    final post = posts.firstWhere((p) => p.id == postId);
    return Scaffold(
      appBar: AppBar(title: Text(post.title)),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Text(post.content),
      ),
    );
  }
}

class CategoryPage extends StatelessWidget {
  final String category;
  const CategoryPage({required this.category});

  @override
  Widget build(BuildContext context) {
    final categoryPosts = posts.where((p) => p.category == category).toList();
    return Scaffold(
      appBar: AppBar(title: Text('Kategorie: $category')),
      body: ListView.builder(
        itemCount: categoryPosts.length,
        itemBuilder: (context, index) {
          final post = categoryPosts[index];
          return ListTile(
            title: Text(post.title),
            onTap: () => context.go('/post/${post.id}'),
          );
        },
      ),
    );
  }
}

class SearchPage extends StatefulWidget {
  final String query;
  const SearchPage({required this.query});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.query);
  }

  @override
  Widget build(BuildContext context) {
    final results = posts.where(
      (p) => p.title.toLowerCase().contains(widget.query.toLowerCase())
    ).toList();

    return Scaffold(
      appBar: AppBar(title: Text('Suche')),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(8),
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Suchen...',
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () => context.go('/search?q=${_controller.text}'),
                ),
              ),
              onSubmitted: (q) => context.go('/search?q=$q'),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: results.length,
              itemBuilder: (context, index) {
                final post = results[index];
                return ListTile(
                  title: Text(post.title),
                  onTap: () => context.go('/post/${post.id}'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## Aufgabe 3

```dart
import 'package:go_router/go_router.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => HomePage(),
        ),
        GoRoute(
          path: '/shop',
          builder: (context, state) => ShopPage(),
          routes: [
            GoRoute(
              path: 'product/:id',
              builder: (context, state) {
                final id = state.pathParameters['id']!;
                return ProductPage(id: id);
              },
            ),
          ],
        ),
        GoRoute(
          path: '/account',
          builder: (context, state) => AccountPage(),
          routes: [
            GoRoute(
              path: 'settings',
              builder: (context, state) => SettingsPage(),
            ),
          ],
        ),
      ],
    ),
  ],
);

class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _getIndex(location),
        onTap: (index) {
          switch (index) {
            case 0: context.go('/');
            case 1: context.go('/shop');
            case 2: context.go('/account');
          }
        },
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.shop), label: 'Shop'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Account'),
        ],
      ),
    );
  }

  int _getIndex(String location) {
    if (location.startsWith('/shop')) return 1;
    if (location.startsWith('/account')) return 2;
    return 0;
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Home')),
      body: Center(child: Text('Home Page')),
    );
  }
}

class ShopPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Shop')),
      body: ListView.builder(
        itemCount: 10,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text('Produkt $index'),
            onTap: () => context.go('/shop/product/$index'),
          );
        },
      ),
    );
  }
}

class ProductPage extends StatelessWidget {
  final String id;
  const ProductPage({required this.id});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Produkt $id')),
      body: Center(child: Text('Produkt Details für ID: $id')),
    );
  }
}

class AccountPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Account')),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(Icons.settings),
            title: Text('Einstellungen'),
            onTap: () => context.go('/account/settings'),
          ),
        ],
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Einstellungen')),
      body: Center(child: Text('Einstellungen')),
    );
  }
}
```

