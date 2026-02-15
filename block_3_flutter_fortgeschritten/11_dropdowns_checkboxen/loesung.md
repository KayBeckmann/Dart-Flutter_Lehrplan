# Lösung 3.11: Dropdowns, Checkboxen & Switches

## Aufgabe 7: Komplett-Formular

```dart
import 'package:flutter/material.dart';

enum MacModel {
  air('MacBook Air', 1199),
  pro14('MacBook Pro 14"', 1999),
  pro16('MacBook Pro 16"', 2499);

  final String name;
  final int basePrice;

  const MacModel(this.name, this.basePrice);
}

enum MacColor { spaceGray, silver }

class ProductConfigForm extends StatefulWidget {
  const ProductConfigForm({super.key});

  @override
  State<ProductConfigForm> createState() => _ProductConfigFormState();
}

class _ProductConfigFormState extends State<ProductConfigForm> {
  final _formKey = GlobalKey<FormState>();

  // Selections
  MacModel? _selectedModel;
  MacColor _selectedColor = MacColor.spaceGray;
  String _selectedStorage = '256GB';
  bool _appleCare = false;
  bool _magicMouse = false;
  bool _magicKeyboard = false;
  bool _engraving = false;
  bool _giftWrap = false;

  final _engravingController = TextEditingController();

  // Preise
  final _storagePrices = {
    '256GB': 0,
    '512GB': 200,
    '1TB': 400,
    '2TB': 600,
  };

  int get _totalPrice {
    if (_selectedModel == null) return 0;

    int price = _selectedModel!.basePrice;
    price += _storagePrices[_selectedStorage] ?? 0;
    if (_appleCare) price += 149;
    if (_magicMouse) price += 99;
    if (_magicKeyboard) price += 129;
    if (_giftWrap) price += 10;

    return price;
  }

  void _addToCart() {
    if (_formKey.currentState!.validate()) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Zum Warenkorb hinzugefügt'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Modell: ${_selectedModel!.name}'),
              Text('Farbe: ${_selectedColor.name}'),
              Text('Speicher: $_selectedStorage'),
              if (_appleCare) const Text('+ AppleCare+'),
              if (_magicMouse) const Text('+ Magic Mouse'),
              if (_magicKeyboard) const Text('+ Magic Keyboard'),
              if (_engraving) Text('Gravur: ${_engravingController.text}'),
              if (_giftWrap) const Text('+ Geschenkverpackung'),
              const Divider(),
              Text(
                'Gesamt: ${_totalPrice}€',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    _engravingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Produkt konfigurieren')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Modell Dropdown
            DropdownButtonFormField<MacModel>(
              value: _selectedModel,
              decoration: const InputDecoration(
                labelText: 'Modell',
                border: OutlineInputBorder(),
              ),
              hint: const Text('Modell auswählen'),
              items: MacModel.values.map((model) {
                return DropdownMenuItem(
                  value: model,
                  child: Text('${model.name} (ab ${model.basePrice}€)'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedModel = value);
              },
              validator: (value) {
                if (value == null) return 'Bitte Modell auswählen';
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Farbe Radio
            const Text('Farbe',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<MacColor>(
                    title: const Text('Space Grau'),
                    value: MacColor.spaceGray,
                    groupValue: _selectedColor,
                    onChanged: (v) => setState(() => _selectedColor = v!),
                  ),
                ),
                Expanded(
                  child: RadioListTile<MacColor>(
                    title: const Text('Silber'),
                    value: MacColor.silver,
                    groupValue: _selectedColor,
                    onChanged: (v) => setState(() => _selectedColor = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Speicher ChoiceChips
            const Text('Speicher',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _storagePrices.entries.map((entry) {
                final label = entry.value > 0
                    ? '${entry.key} (+${entry.value}€)'
                    : entry.key;
                return ChoiceChip(
                  label: Text(label),
                  selected: _selectedStorage == entry.key,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedStorage = entry.key);
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Extras Checkboxes
            const Text('Extras',
                style: TextStyle(fontWeight: FontWeight.bold)),
            CheckboxListTile(
              title: const Text('AppleCare+'),
              subtitle: const Text('+149€'),
              value: _appleCare,
              onChanged: (v) => setState(() => _appleCare = v!),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            CheckboxListTile(
              title: const Text('Magic Mouse'),
              subtitle: const Text('+99€'),
              value: _magicMouse,
              onChanged: (v) => setState(() => _magicMouse = v!),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            CheckboxListTile(
              title: const Text('Magic Keyboard'),
              subtitle: const Text('+129€'),
              value: _magicKeyboard,
              onChanged: (v) => setState(() => _magicKeyboard = v!),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const SizedBox(height: 16),

            // Gravur Switch
            SwitchListTile(
              title: const Text('Gravur'),
              subtitle: const Text('Personalisierte Gravur hinzufügen'),
              value: _engraving,
              onChanged: (v) => setState(() => _engraving = v),
            ),
            if (_engraving)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextFormField(
                  controller: _engravingController,
                  decoration: const InputDecoration(
                    labelText: 'Gravurtext',
                    hintText: 'Max. 20 Zeichen',
                    border: OutlineInputBorder(),
                  ),
                  maxLength: 20,
                  validator: (value) {
                    if (_engraving && (value == null || value.isEmpty)) {
                      return 'Bitte Gravurtext eingeben';
                    }
                    return null;
                  },
                ),
              ),
            const SizedBox(height: 8),

            // Geschenkverpackung Switch
            SwitchListTile(
              title: const Text('Geschenkverpackung'),
              subtitle: const Text('+10€'),
              value: _giftWrap,
              onChanged: (v) => setState(() => _giftWrap = v),
            ),

            const Divider(height: 32),

            // Preis
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Gesamtpreis:',
                    style: TextStyle(fontSize: 18),
                  ),
                  Text(
                    '${_totalPrice}€',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _selectedModel == null ? null : _addToCart,
                icon: const Icon(Icons.shopping_cart),
                label: const Text('In den Warenkorb'),
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

## Aufgabe 2: Newsletter Checkboxen

```dart
class NewsletterSettings extends StatefulWidget {
  const NewsletterSettings({super.key});

  @override
  State<NewsletterSettings> createState() => _NewsletterSettingsState();
}

class _NewsletterSettingsState extends State<NewsletterSettings> {
  bool _subscribed = false;
  bool _weekly = true;
  bool _monthly = false;
  bool _products = true;
  bool _offers = false;

  List<bool> get _options => [_weekly, _monthly, _products, _offers];

  bool get _allSelected => _options.every((o) => o);
  bool get _noneSelected => _options.every((o) => !o);

  void _selectAll() {
    setState(() {
      _weekly = true;
      _monthly = true;
      _products = true;
      _offers = true;
    });
  }

  void _selectNone() {
    setState(() {
      _weekly = false;
      _monthly = false;
      _products = false;
      _offers = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Newsletter Einstellungen',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Haupt-Checkbox
            CheckboxListTile(
              title: const Text('Newsletter abonnieren'),
              value: _subscribed,
              onChanged: (v) => setState(() => _subscribed = v!),
              controlAffinity: ListTileControlAffinity.leading,
            ),

            // Unteroptionen
            if (_subscribed) ...[
              const Divider(),
              CheckboxListTile(
                title: const Text('Wöchentliche Updates'),
                value: _weekly,
                onChanged: (v) => setState(() => _weekly = v!),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              CheckboxListTile(
                title: const Text('Monatliche Zusammenfassung'),
                value: _monthly,
                onChanged: (v) => setState(() => _monthly = v!),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              CheckboxListTile(
                title: const Text('Produktneuheiten'),
                value: _products,
                onChanged: (v) => setState(() => _products = v!),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              CheckboxListTile(
                title: const Text('Sonderangebote'),
                value: _offers,
                onChanged: (v) => setState(() => _offers = v!),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  TextButton(
                    onPressed: _allSelected ? null : _selectAll,
                    child: const Text('Alle auswählen'),
                  ),
                  TextButton(
                    onPressed: _noneSelected ? null : _selectNone,
                    child: const Text('Keine'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

---

## Aufgabe 5: Filter Chips

```dart
class TagFilter extends StatefulWidget {
  const TagFilter({super.key});

  @override
  State<TagFilter> createState() => _TagFilterState();
}

class _TagFilterState extends State<TagFilter> {
  final _allTags = ['Web', 'App', 'API', 'DB', 'UI/UX', 'DevOps', 'Testing'];
  final Set<String> _selectedTags = {};

  void _applyFilter() {
    if (_selectedTags.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte mindestens einen Tag auswählen')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Filter angewendet: ${_selectedTags.join(', ')}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kategorien filtern',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _allTags.map((tag) {
                return FilterChip(
                  label: Text(tag),
                  selected: _selectedTags.contains(tag),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedTags.add(tag);
                      } else {
                        _selectedTags.remove(tag);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Text('Ausgewählt: ${_selectedTags.isEmpty ? "Keine" : _selectedTags.join(", ")}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _applyFilter,
              child: const Text('Filter anwenden'),
            ),
          ],
        ),
      ),
    );
  }
}
```
