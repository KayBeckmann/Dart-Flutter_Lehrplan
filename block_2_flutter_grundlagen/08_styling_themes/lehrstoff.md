# Einheit 2.8: Styling & Themes

> **Dauer:** 2 Stunden | **Voraussetzungen:** Einheit 2.7

---

## 8.1 ThemeData

```dart
MaterialApp(
  theme: ThemeData(
    primarySwatch: Colors.blue,
    brightness: Brightness.light,
    scaffoldBackgroundColor: Colors.grey[100],
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
  ),
  darkTheme: ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.blue,
  ),
  themeMode: ThemeMode.system,  // system, light, dark
  home: MyApp(),
)
```

---

## 8.2 ColorScheme

```dart
ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.deepPurple,
    brightness: Brightness.light,
  ),
)

// Verwendung
Container(
  color: Theme.of(context).colorScheme.primary,
)

// ColorScheme Farben
colorScheme.primary        // Hauptfarbe
colorScheme.onPrimary      // Text auf primary
colorScheme.secondary      // Sekundärfarbe
colorScheme.onSecondary    // Text auf secondary
colorScheme.surface        // Oberfläche (Cards, etc.)
colorScheme.onSurface      // Text auf surface
colorScheme.error          // Fehlerfarbe
colorScheme.onError        // Text auf error
```

---

## 8.3 TextTheme

```dart
ThemeData(
  textTheme: TextTheme(
    displayLarge: TextStyle(fontSize: 57, fontWeight: FontWeight.bold),
    displayMedium: TextStyle(fontSize: 45),
    displaySmall: TextStyle(fontSize: 36),
    headlineLarge: TextStyle(fontSize: 32),
    headlineMedium: TextStyle(fontSize: 28),
    headlineSmall: TextStyle(fontSize: 24),
    titleLarge: TextStyle(fontSize: 22),
    titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
    titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
    bodyLarge: TextStyle(fontSize: 16),
    bodyMedium: TextStyle(fontSize: 14),
    bodySmall: TextStyle(fontSize: 12),
    labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
    labelMedium: TextStyle(fontSize: 12),
    labelSmall: TextStyle(fontSize: 11),
  ),
)

// Verwendung
Text(
  'Überschrift',
  style: Theme.of(context).textTheme.headlineMedium,
)
```

---

## 8.4 Button Styles

```dart
ThemeData(
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: Colors.blue,
      side: BorderSide(color: Colors.blue),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: Colors.blue,
    ),
  ),
)

// Individuelles Styling
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.red,
    minimumSize: Size(200, 50),
  ),
  onPressed: () {},
  child: Text('Button'),
)
```

---

## 8.5 Input Decoration Theme

```dart
ThemeData(
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    filled: true,
    fillColor: Colors.grey[100],
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    prefixIconColor: Colors.grey,
    suffixIconColor: Colors.grey,
    labelStyle: TextStyle(color: Colors.grey[700]),
    hintStyle: TextStyle(color: Colors.grey[400]),
    errorStyle: TextStyle(color: Colors.red),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.blue, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.red),
    ),
  ),
)
```

---

## 8.6 Card & Dialog Theme

```dart
ThemeData(
  cardTheme: CardTheme(
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    margin: EdgeInsets.all(8),
  ),
  dialogTheme: DialogTheme(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    titleTextStyle: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: Colors.black,
    ),
  ),
)
```

---

## 8.7 Theme Extensions

```dart
// Eigene Theme-Erweiterung definieren
class CustomColors extends ThemeExtension<CustomColors> {
  final Color? success;
  final Color? warning;

  CustomColors({this.success, this.warning});

  @override
  CustomColors copyWith({Color? success, Color? warning}) {
    return CustomColors(
      success: success ?? this.success,
      warning: warning ?? this.warning,
    );
  }

  @override
  CustomColors lerp(ThemeExtension<CustomColors>? other, double t) {
    if (other is! CustomColors) return this;
    return CustomColors(
      success: Color.lerp(success, other.success, t),
      warning: Color.lerp(warning, other.warning, t),
    );
  }
}

// Im Theme registrieren
ThemeData(
  extensions: [
    CustomColors(
      success: Colors.green,
      warning: Colors.orange,
    ),
  ],
)

// Verwenden
final customColors = Theme.of(context).extension<CustomColors>()!;
Container(color: customColors.success)
```

---

## 8.8 Google Fonts

```yaml
# pubspec.yaml
dependencies:
  google_fonts: ^6.1.0
```

```dart
import 'package:google_fonts/google_fonts.dart';

// Einzelner Text
Text(
  'Hello',
  style: GoogleFonts.roboto(fontSize: 24),
)

// Im Theme
ThemeData(
  textTheme: GoogleFonts.latoTextTheme(),
)

// Angepasstes TextTheme
ThemeData(
  textTheme: GoogleFonts.latoTextTheme().copyWith(
    headlineMedium: GoogleFonts.oswald(fontSize: 28),
  ),
)
```

---

## 8.9 Beispiel: Komplettes Theme

```dart
class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Color(0xFF6750A4),
        brightness: Brightness.light,
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Color(0xFF6750A4),
        brightness: Brightness.dark,
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

// Verwendung
MaterialApp(
  theme: AppTheme.lightTheme,
  darkTheme: AppTheme.darkTheme,
  themeMode: ThemeMode.system,
  home: MyApp(),
)
```

