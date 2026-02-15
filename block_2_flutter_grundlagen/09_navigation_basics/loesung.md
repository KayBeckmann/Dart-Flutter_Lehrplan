# Lösung 2.9: Navigation Basics

---

## Aufgabe 1

```dart
class Product {
  final int id;
  final String name;
  final String description;
  final double price;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
  });
}

class ProductListPage extends StatelessWidget {
  final products = [
    Product(id: 1, name: 'Laptop', description: 'Schneller Laptop', price: 999.99),
    Product(id: 2, name: 'Maus', description: 'Wireless Maus', price: 49.99),
    Product(id: 3, name: 'Tastatur', description: 'Mechanisch', price: 129.99),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Produkte')),
      body: ListView.builder(
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return ListTile(
            leading: CircleAvatar(child: Text('${product.id}')),
            title: Text(product.name),
            subtitle: Text('€${product.price.toStringAsFixed(2)}'),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductDetailPage(product: product),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class ProductDetailPage extends StatelessWidget {
  final Product product;

  const ProductDetailPage({required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(product.name)),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 200,
              width: double.infinity,
              color: Colors.grey[200],
              child: Icon(Icons.image, size: 80, color: Colors.grey),
            ),
            SizedBox(height: 16),
            Text(product.name, style: TextStyle(
              fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('€${product.price.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 20, color: Colors.green)),
            SizedBox(height: 16),
            Text(product.description, style: TextStyle(fontSize: 16)),
            Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                child: Text('In den Warenkorb'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## Aufgabe 2

```dart
class EditFormPage extends StatefulWidget {
  @override
  State<EditFormPage> createState() => _EditFormPageState();
}

class _EditFormPageState extends State<EditFormPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onChanged);
    _emailController.addListener(_onChanged);
  }

  void _onChanged() {
    setState(() => _hasChanges = true);
  }

  Future<bool> _confirmDiscard() async {
    if (!_hasChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Änderungen verwerfen?'),
        content: Text('Nicht gespeicherte Änderungen gehen verloren.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Verwerfen'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _save() {
    final data = {
      'name': _nameController.text,
      'email': _emailController.text,
    };
    Navigator.pop(context, data);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _confirmDiscard();
        if (shouldPop && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Bearbeiten'),
          actions: [
            TextButton(
              onPressed: _save,
              child: Text('Speichern'),
            ),
          ],
        ),
        body: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Name'),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}
```

---

## Aufgabe 3

```dart
class TabApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            title: Text('Tab Navigation'),
            bottom: TabBar(
              tabs: [
                Tab(icon: Icon(Icons.feed), text: 'Feed'),
                Tab(icon: Icon(Icons.search), text: 'Suche'),
                Tab(icon: Icon(Icons.person), text: 'Profil'),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              FeedTab(),
              SearchTab(),
              ProfileTab(),
            ],
          ),
        ),
      ),
    );
  }
}

class FeedTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 20,
      itemBuilder: (context, index) {
        return Card(
          margin: EdgeInsets.all(8),
          child: ListTile(
            leading: CircleAvatar(child: Text('${index + 1}')),
            title: Text('Post $index'),
            subtitle: Text('Beschreibung des Posts'),
          ),
        );
      },
    );
  }
}

class SearchTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Suchen...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 16),
          Expanded(
            child: Center(child: Text('Suchergebnisse erscheinen hier')),
          ),
        ],
      ),
    );
  }
}

class ProfileTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(radius: 50, child: Icon(Icons.person, size: 50)),
          SizedBox(height: 16),
          Text('Benutzername', style: TextStyle(fontSize: 24)),
          SizedBox(height: 8),
          Text('user@example.com'),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {},
            child: Text('Profil bearbeiten'),
          ),
        ],
      ),
    );
  }
}
```

