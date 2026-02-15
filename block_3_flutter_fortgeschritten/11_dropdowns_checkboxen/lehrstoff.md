# Einheit 3.11: Dropdowns, Checkboxen & Switches

## Lernziele

Nach dieser Einheit kannst du:
- `DropdownButtonFormField` in Formularen verwenden
- `Checkbox`, `Switch` und `Radio` einsetzen
- `ChoiceChip` und `FilterChip` verwenden
- Custom FormFields erstellen

---

## 1. DropdownButtonFormField

### Basis-Verwendung

```dart
class MyForm extends StatefulWidget {
  @override
  State<MyForm> createState() => _MyFormState();
}

class _MyFormState extends State<MyForm> {
  String? _selectedCountry;

  final _countries = ['Deutschland', 'Österreich', 'Schweiz'];

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: _selectedCountry,
      decoration: const InputDecoration(
        labelText: 'Land',
        border: OutlineInputBorder(),
      ),
      items: _countries.map((country) {
        return DropdownMenuItem(
          value: country,
          child: Text(country),
        );
      }).toList(),
      onChanged: (value) {
        setState(() => _selectedCountry = value);
      },
      validator: (value) {
        if (value == null) return 'Bitte Land auswählen';
        return null;
      },
    );
  }
}
```

### Mit Enum

```dart
enum Priority { low, medium, high }

extension PriorityLabel on Priority {
  String get label {
    switch (this) {
      case Priority.low:
        return 'Niedrig';
      case Priority.medium:
        return 'Mittel';
      case Priority.high:
        return 'Hoch';
    }
  }

  Color get color {
    switch (this) {
      case Priority.low:
        return Colors.green;
      case Priority.medium:
        return Colors.orange;
      case Priority.high:
        return Colors.red;
    }
  }
}

// Verwendung
DropdownButtonFormField<Priority>(
  value: _priority,
  decoration: const InputDecoration(labelText: 'Priorität'),
  items: Priority.values.map((p) {
    return DropdownMenuItem(
      value: p,
      child: Row(
        children: [
          Icon(Icons.circle, color: p.color, size: 12),
          const SizedBox(width: 8),
          Text(p.label),
        ],
      ),
    );
  }).toList(),
  onChanged: (value) => setState(() => _priority = value),
);
```

### Hint und DisabledHint

```dart
DropdownButtonFormField<String>(
  value: _value,
  hint: const Text('Bitte auswählen'),       // Wenn value == null
  disabledHint: const Text('Nicht verfügbar'), // Wenn onChanged == null
  items: _items,
  onChanged: _isEnabled ? (v) => setState(() => _value = v) : null,
);
```

---

## 2. Checkbox

### Einfache Checkbox

```dart
class CheckboxDemo extends StatefulWidget {
  @override
  State<CheckboxDemo> createState() => _CheckboxDemoState();
}

class _CheckboxDemoState extends State<CheckboxDemo> {
  bool _isChecked = false;

  @override
  Widget build(BuildContext context) {
    return Checkbox(
      value: _isChecked,
      onChanged: (value) {
        setState(() => _isChecked = value ?? false);
      },
    );
  }
}
```

### CheckboxListTile

```dart
CheckboxListTile(
  title: const Text('Newsletter abonnieren'),
  subtitle: const Text('Wöchentliche Updates erhalten'),
  secondary: const Icon(Icons.mail),
  value: _subscribeNewsletter,
  onChanged: (value) {
    setState(() => _subscribeNewsletter = value ?? false);
  },
  controlAffinity: ListTileControlAffinity.leading,  // Checkbox links
);
```

### Tristate Checkbox

```dart
bool? _value;  // null, true, oder false

Checkbox(
  tristate: true,
  value: _value,
  onChanged: (value) {
    setState(() => _value = value);
  },
);

// Visuell:
// null → Strich (-)
// true → Häkchen (✓)
// false → Leer
```

### AGBs Checkbox mit Validierung

```dart
class TermsCheckbox extends FormField<bool> {
  TermsCheckbox({
    super.key,
    required bool value,
    required ValueChanged<bool> onChanged,
    String? Function(bool?)? validator,
  }) : super(
          initialValue: value,
          validator: validator,
          builder: (state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CheckboxListTile(
                  title: const Text('Ich akzeptiere die AGBs'),
                  value: state.value,
                  onChanged: (v) {
                    state.didChange(v);
                    onChanged(v ?? false);
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                if (state.hasError)
                  Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Text(
                      state.errorText!,
                      style: TextStyle(
                        color: Theme.of(state.context).colorScheme.error,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            );
          },
        );
}

// Verwendung
TermsCheckbox(
  value: _acceptTerms,
  onChanged: (value) => setState(() => _acceptTerms = value),
  validator: (value) {
    if (value != true) return 'Bitte AGBs akzeptieren';
    return null;
  },
);
```

---

## 3. Switch

### Einfacher Switch

```dart
Switch(
  value: _darkMode,
  onChanged: (value) {
    setState(() => _darkMode = value);
  },
);
```

### SwitchListTile

```dart
SwitchListTile(
  title: const Text('Dark Mode'),
  subtitle: const Text('Dunkles Farbschema verwenden'),
  secondary: const Icon(Icons.dark_mode),
  value: _darkMode,
  onChanged: (value) {
    setState(() => _darkMode = value);
  },
);
```

### Adaptive Switch (Platform-spezifisch)

```dart
Switch.adaptive(
  value: _value,
  onChanged: (value) => setState(() => _value = value),
);
// iOS: CupertinoSwitch
// Android: Material Switch
```

---

## 4. Radio

### Radio Buttons

```dart
enum Gender { male, female, other }

class GenderSelector extends StatefulWidget {
  @override
  State<GenderSelector> createState() => _GenderSelectorState();
}

class _GenderSelectorState extends State<GenderSelector> {
  Gender? _gender;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RadioListTile<Gender>(
          title: const Text('Männlich'),
          value: Gender.male,
          groupValue: _gender,
          onChanged: (value) => setState(() => _gender = value),
        ),
        RadioListTile<Gender>(
          title: const Text('Weiblich'),
          value: Gender.female,
          groupValue: _gender,
          onChanged: (value) => setState(() => _gender = value),
        ),
        RadioListTile<Gender>(
          title: const Text('Divers'),
          value: Gender.other,
          groupValue: _gender,
          onChanged: (value) => setState(() => _gender = value),
        ),
      ],
    );
  }
}
```

### Horizontale Radio Buttons

```dart
Row(
  children: Gender.values.map((g) {
    return Expanded(
      child: RadioListTile<Gender>(
        title: Text(g.name),
        value: g,
        groupValue: _gender,
        onChanged: (v) => setState(() => _gender = v),
        contentPadding: EdgeInsets.zero,
      ),
    );
  }).toList(),
);
```

---

## 5. ChoiceChip & FilterChip

### ChoiceChip (Single Selection)

```dart
class SizeSelector extends StatefulWidget {
  @override
  State<SizeSelector> createState() => _SizeSelectorState();
}

class _SizeSelectorState extends State<SizeSelector> {
  String? _selectedSize;
  final _sizes = ['XS', 'S', 'M', 'L', 'XL'];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: _sizes.map((size) {
        return ChoiceChip(
          label: Text(size),
          selected: _selectedSize == size,
          onSelected: (selected) {
            setState(() {
              _selectedSize = selected ? size : null;
            });
          },
        );
      }).toList(),
    );
  }
}
```

### FilterChip (Multi Selection)

```dart
class TagSelector extends StatefulWidget {
  @override
  State<TagSelector> createState() => _TagSelectorState();
}

class _TagSelectorState extends State<TagSelector> {
  final _allTags = ['Flutter', 'Dart', 'Firebase', 'API', 'UI/UX'];
  final Set<String> _selectedTags = {};

  @override
  Widget build(BuildContext context) {
    return Wrap(
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
    );
  }
}
```

### InputChip (mit Löschfunktion)

```dart
Wrap(
  spacing: 8,
  children: _selectedItems.map((item) {
    return InputChip(
      label: Text(item),
      onDeleted: () {
        setState(() => _selectedItems.remove(item));
      },
      deleteIcon: const Icon(Icons.close, size: 18),
    );
  }).toList(),
);
```

---

## 6. Custom FormField

### Multi-Select als FormField

```dart
class MultiSelectFormField<T> extends FormField<Set<T>> {
  MultiSelectFormField({
    super.key,
    required List<T> options,
    required String Function(T) labelBuilder,
    Set<T>? initialValue,
    String? Function(Set<T>?)? validator,
    void Function(Set<T>?)? onSaved,
  }) : super(
          initialValue: initialValue ?? {},
          validator: validator,
          onSaved: onSaved,
          builder: (state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: options.map((option) {
                    final selected = state.value?.contains(option) ?? false;
                    return FilterChip(
                      label: Text(labelBuilder(option)),
                      selected: selected,
                      onSelected: (isSelected) {
                        final newValue = Set<T>.from(state.value ?? {});
                        if (isSelected) {
                          newValue.add(option);
                        } else {
                          newValue.remove(option);
                        }
                        state.didChange(newValue);
                      },
                    );
                  }).toList(),
                ),
                if (state.hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      state.errorText!,
                      style: TextStyle(
                        color: Theme.of(state.context).colorScheme.error,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            );
          },
        );
}

// Verwendung
MultiSelectFormField<String>(
  options: ['Option A', 'Option B', 'Option C'],
  labelBuilder: (option) => option,
  validator: (value) {
    if (value == null || value.isEmpty) {
      return 'Bitte mindestens eine Option wählen';
    }
    return null;
  },
  onSaved: (value) {
    print('Selected: $value');
  },
);
```

---

## 7. Segmented Button (Material 3)

```dart
enum View { list, grid, table }

class ViewSelector extends StatefulWidget {
  @override
  State<ViewSelector> createState() => _ViewSelectorState();
}

class _ViewSelectorState extends State<ViewSelector> {
  View _selectedView = View.list;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<View>(
      segments: const [
        ButtonSegment(
          value: View.list,
          label: Text('Liste'),
          icon: Icon(Icons.list),
        ),
        ButtonSegment(
          value: View.grid,
          label: Text('Grid'),
          icon: Icon(Icons.grid_view),
        ),
        ButtonSegment(
          value: View.table,
          label: Text('Tabelle'),
          icon: Icon(Icons.table_chart),
        ),
      ],
      selected: {_selectedView},
      onSelectionChanged: (selected) {
        setState(() => _selectedView = selected.first);
      },
    );
  }
}
```

### Multi-Select Segmented Button

```dart
Set<String> _selectedDays = {'Mo', 'Mi', 'Fr'};

SegmentedButton<String>(
  segments: ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So']
      .map((d) => ButtonSegment(value: d, label: Text(d)))
      .toList(),
  selected: _selectedDays,
  onSelectionChanged: (selected) {
    setState(() => _selectedDays = selected);
  },
  multiSelectionEnabled: true,
);
```

---

## Zusammenfassung

| Widget | Use Case |
|--------|----------|
| `DropdownButtonFormField` | Einzelauswahl aus Liste |
| `Checkbox` / `CheckboxListTile` | Boolean Werte |
| `Switch` / `SwitchListTile` | Ein/Aus Toggle |
| `Radio` / `RadioListTile` | Exklusive Auswahl |
| `ChoiceChip` | Einzelauswahl (kompakt) |
| `FilterChip` | Mehrfachauswahl |
| `InputChip` | Auswahl mit Löschfunktion |
| `SegmentedButton` | Exklusive/Multi Auswahl (Material 3) |

**Tipps:**
- `ListTile` Varianten für bessere Beschriftung
- `Wrap` für flexible Chip-Layouts
- Custom `FormField` für komplexe Validierung
- Enum + Extension für typsichere Auswahlen
