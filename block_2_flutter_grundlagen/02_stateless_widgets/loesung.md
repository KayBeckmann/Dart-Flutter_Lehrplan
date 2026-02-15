# Lösung 2.2: StatelessWidget & Basis-Widgets

---

## Aufgabe 1: Visitenkarte

```dart
class Visitenkarte extends StatelessWidget {
  final String name;
  final String position;
  final String firma;
  final String email;
  final String telefon;

  const Visitenkarte({
    super.key,
    required this.name,
    required this.position,
    required this.firma,
    required this.email,
    required this.telefon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(name, style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            )),
            const SizedBox(height: 4),
            Text(position, style: const TextStyle(fontSize: 16)),
            Text(firma, style: TextStyle(color: Colors.grey[600])),
            const Divider(height: 24),
            _kontaktZeile(Icons.email, email),
            const SizedBox(height: 8),
            _kontaktZeile(Icons.phone, telefon),
          ],
        ),
      ),
    );
  }

  Widget _kontaktZeile(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.blue),
        const SizedBox(width: 12),
        Text(text),
      ],
    );
  }
}
```

---

## Aufgabe 2: Produktkarte

```dart
class ProduktKarte extends StatelessWidget {
  final String name;
  final double preis;
  final String bildUrl;
  final bool aufLager;

  const ProduktKarte({
    super.key,
    required this.name,
    required this.preis,
    required this.bildUrl,
    required this.aufLager,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Image.network(
                bildUrl,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: aufLager ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    aufLager ? 'Auf Lager' : 'Ausverkauft',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                )),
                const SizedBox(height: 4),
                Text('${preis.toStringAsFixed(2)} €',
                  style: const TextStyle(fontSize: 16, color: Colors.green)),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: aufLager ? () {} : null,
                    icon: const Icon(Icons.shopping_cart),
                    label: const Text('In den Warenkorb'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## Aufgabe 3: Bewertung

```dart
class Bewertung extends StatelessWidget {
  final int sterne;
  final int maxSterne;
  final int? anzahlBewertungen;

  const Bewertung({
    super.key,
    required this.sterne,
    this.maxSterne = 5,
    this.anzahlBewertungen,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(maxSterne, (i) => Icon(
          i < sterne ? Icons.star : Icons.star_border,
          color: i < sterne ? Colors.amber : Colors.grey,
          size: 24,
        )),
        if (anzahlBewertungen != null) ...[
          const SizedBox(width: 8),
          Text('($anzahlBewertungen)', style: TextStyle(color: Colors.grey)),
        ],
      ],
    );
  }
}
```
