# Einheit 2.7: Listen & Scrolling

> **Dauer:** 2 Stunden | **Voraussetzungen:** Einheit 2.6

---

## 7.1 ListView

```dart
// Einfache ListView
ListView(
  children: [
    ListTile(title: Text('Eintrag 1')),
    ListTile(title: Text('Eintrag 2')),
    ListTile(title: Text('Eintrag 3')),
  ],
)

// ListView.builder — für lange Listen (lazy loading)
ListView.builder(
  itemCount: 100,
  itemBuilder: (context, index) {
    return ListTile(
      leading: CircleAvatar(child: Text('$index')),
      title: Text('Element $index'),
      subtitle: Text('Beschreibung'),
      trailing: Icon(Icons.arrow_forward_ios),
      onTap: () => print('Tapped $index'),
    );
  },
)
```

---

## 7.2 ListView.separated

```dart
ListView.separated(
  itemCount: 20,
  itemBuilder: (context, index) {
    return ListTile(title: Text('Eintrag $index'));
  },
  separatorBuilder: (context, index) {
    return Divider(height: 1);
  },
)
```

---

## 7.3 GridView

```dart
// GridView.count — feste Spaltenanzahl
GridView.count(
  crossAxisCount: 2,
  mainAxisSpacing: 8,
  crossAxisSpacing: 8,
  padding: EdgeInsets.all(8),
  children: List.generate(10, (i) => Card(
    child: Center(child: Text('Item $i')),
  )),
)

// GridView.builder — lazy loading
GridView.builder(
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 3,
    mainAxisSpacing: 4,
    crossAxisSpacing: 4,
    childAspectRatio: 1.0,
  ),
  itemCount: 50,
  itemBuilder: (context, index) {
    return Container(
      color: Colors.primaries[index % Colors.primaries.length],
      child: Center(child: Text('$index')),
    );
  },
)

// GridView.extent — maximale Breite pro Item
GridView.extent(
  maxCrossAxisExtent: 150,
  children: [...],
)
```

---

## 7.4 SingleChildScrollView

```dart
// Für einzelne scrollbare Inhalte
SingleChildScrollView(
  child: Column(
    children: [
      Container(height: 200, color: Colors.red),
      Container(height: 200, color: Colors.green),
      Container(height: 200, color: Colors.blue),
      // ... mehr Inhalte
    ],
  ),
)

// Mit horizontalem Scrolling
SingleChildScrollView(
  scrollDirection: Axis.horizontal,
  child: Row(
    children: List.generate(10, (i) => Container(
      width: 150,
      height: 100,
      margin: EdgeInsets.all(8),
      color: Colors.primaries[i],
    )),
  ),
)
```

---

## 7.5 ScrollController

```dart
class ScrollExample extends StatefulWidget {
  @override
  State<ScrollExample> createState() => _ScrollExampleState();
}

class _ScrollExampleState extends State<ScrollExample> {
  final _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
  }

  void _onScroll() {
    print('Position: ${_controller.offset}');
    if (_controller.position.atEdge) {
      if (_controller.position.pixels == 0) {
        print('Am Anfang');
      } else {
        print('Am Ende');
      }
    }
  }

  void _scrollToTop() {
    _controller.animateTo(
      0,
      duration: Duration(milliseconds: 500),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _controller,
      itemCount: 50,
      itemBuilder: (context, index) => ListTile(title: Text('Item $index')),
    );
  }
}
```

---

## 7.6 RefreshIndicator (Pull-to-Refresh)

```dart
class RefreshExample extends StatefulWidget {
  @override
  State<RefreshExample> createState() => _RefreshExampleState();
}

class _RefreshExampleState extends State<RefreshExample> {
  List<String> items = List.generate(10, (i) => 'Item $i');

  Future<void> _refresh() async {
    await Future.delayed(Duration(seconds: 2));
    setState(() {
      items = List.generate(10, (i) => 'Neu geladen $i');
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          return ListTile(title: Text(items[index]));
        },
      ),
    );
  }
}
```

---

## 7.7 CustomScrollView & Slivers

```dart
CustomScrollView(
  slivers: [
    // Collapsing Header
    SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text('Titel'),
        background: Image.network(
          'https://picsum.photos/400/200',
          fit: BoxFit.cover,
        ),
      ),
    ),
    // Liste
    SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => ListTile(title: Text('Item $index')),
        childCount: 20,
      ),
    ),
    // Grid
    SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) => Card(child: Center(child: Text('Grid $index'))),
        childCount: 10,
      ),
    ),
  ],
)
```

---

## 7.8 Beispiel: Kontaktliste mit Suche

```dart
class ContactList extends StatefulWidget {
  @override
  State<ContactList> createState() => _ContactListState();
}

class _ContactListState extends State<ContactList> {
  final allContacts = [
    'Anna', 'Bob', 'Clara', 'David', 'Eva',
    'Frank', 'Greta', 'Hans', 'Iris', 'Jan',
  ];

  List<String> filteredContacts = [];
  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    filteredContacts = allContacts;
  }

  void _filter(String query) {
    setState(() {
      filteredContacts = allContacts
          .where((c) => c.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(8),
          child: TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'Suchen...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: _filter,
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: filteredContacts.length,
            itemBuilder: (context, index) {
              final contact = filteredContacts[index];
              return ListTile(
                leading: CircleAvatar(child: Text(contact[0])),
                title: Text(contact),
              );
            },
          ),
        ),
      ],
    );
  }
}
```

