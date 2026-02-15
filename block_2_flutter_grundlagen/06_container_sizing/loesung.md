# Lösung 2.6: Container, Sizing & Spacing

---

## Aufgabe 1

```dart
Row(
  children: [
    Expanded(child: ElevatedButton(onPressed: () {}, child: Text('Eins'))),
    SizedBox(width: 8),
    Expanded(child: ElevatedButton(onPressed: () {}, child: Text('Zwei'))),
    SizedBox(width: 8),
    Expanded(child: ElevatedButton(onPressed: () {}, child: Text('Drei'))),
  ],
)
```

---

## Aufgabe 2

```dart
class PricingCard extends StatelessWidget {
  final String titel;
  final double preis;
  final List<(String, bool)> features;
  final Color farbe;

  const PricingCard({
    super.key,
    required this.titel,
    required this.preis,
    required this.features,
    this.farbe = Colors.blue,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(24),
            color: farbe,
            child: Column(
              children: [
                Text(titel, style: TextStyle(
                  color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('€${preis.toStringAsFixed(2)}/mo',
                  style: TextStyle(color: Colors.white, fontSize: 28)),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  for (var (text, aktiv) in features)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(aktiv ? Icons.check : Icons.close,
                            color: aktiv ? Colors.green : Colors.grey),
                          SizedBox(width: 8),
                          Text(text, style: TextStyle(
                            color: aktiv ? null : Colors.grey)),
                        ],
                      ),
                    ),
                  Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(backgroundColor: farbe),
                      child: Text('Auswählen'),
                    ),
                  ),
                ],
              ),
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
GridView.count(
  crossAxisCount: 2,
  mainAxisSpacing: 8,
  crossAxisSpacing: 8,
  children: List.generate(4, (i) => AspectRatio(
    aspectRatio: 1,
    child: Image.network('https://picsum.photos/200?$i', fit: BoxFit.cover),
  )),
)
```
