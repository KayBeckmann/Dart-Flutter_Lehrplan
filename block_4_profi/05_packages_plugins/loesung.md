# Lösung 4.5: Packages & Plugins

## Aufgabe 2: Validator Package

### Struktur

```
my_validators/
├── lib/
│   ├── my_validators.dart
│   └── src/
│       ├── email_validator.dart
│       ├── password_validator.dart
│       ├── phone_validator.dart
│       └── iban_validator.dart
├── test/
│   └── validators_test.dart
├── example/
│   └── lib/main.dart
├── pubspec.yaml
└── README.md
```

### lib/my_validators.dart

```dart
/// A collection of validators for common use cases.
library my_validators;

export 'src/email_validator.dart';
export 'src/password_validator.dart';
export 'src/phone_validator.dart';
export 'src/iban_validator.dart';
```

### lib/src/email_validator.dart

```dart
/// Validates email addresses.
class EmailValidator {
  static final _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  /// Returns `true` if [email] is a valid email address.
  ///
  /// Example:
  /// ```dart
  /// EmailValidator.isValid('test@example.com'); // true
  /// EmailValidator.isValid('invalid'); // false
  /// ```
  static bool isValid(String email) {
    if (email.isEmpty) return false;
    return _emailRegex.hasMatch(email.trim());
  }

  /// Returns an error message if invalid, `null` if valid.
  static String? validate(String? email) {
    if (email == null || email.isEmpty) {
      return 'Email ist erforderlich';
    }
    if (!isValid(email)) {
      return 'Ungültige Email-Adresse';
    }
    return null;
  }
}
```

### lib/src/password_validator.dart

```dart
/// Configuration for password validation.
class PasswordConfig {
  final int minLength;
  final bool requireUppercase;
  final bool requireLowercase;
  final bool requireDigit;
  final bool requireSpecialChar;

  const PasswordConfig({
    this.minLength = 8,
    this.requireUppercase = true,
    this.requireLowercase = true,
    this.requireDigit = true,
    this.requireSpecialChar = false,
  });

  static const standard = PasswordConfig();
  static const strong = PasswordConfig(
    minLength: 12,
    requireSpecialChar: true,
  );
}

/// Result of password validation.
class PasswordValidationResult {
  final bool isValid;
  final List<String> errors;

  const PasswordValidationResult({
    required this.isValid,
    this.errors = const [],
  });
}

/// Validates passwords with configurable rules.
class PasswordValidator {
  final PasswordConfig config;

  const PasswordValidator({this.config = PasswordConfig.standard});

  /// Validates [password] against configured rules.
  PasswordValidationResult validate(String password) {
    final errors = <String>[];

    if (password.length < config.minLength) {
      errors.add('Mindestens ${config.minLength} Zeichen erforderlich');
    }
    if (config.requireUppercase && !password.contains(RegExp(r'[A-Z]'))) {
      errors.add('Großbuchstabe erforderlich');
    }
    if (config.requireLowercase && !password.contains(RegExp(r'[a-z]'))) {
      errors.add('Kleinbuchstabe erforderlich');
    }
    if (config.requireDigit && !password.contains(RegExp(r'[0-9]'))) {
      errors.add('Ziffer erforderlich');
    }
    if (config.requireSpecialChar && !password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      errors.add('Sonderzeichen erforderlich');
    }

    return PasswordValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }

  /// Convenience method for form validation.
  String? validateForForm(String? password) {
    if (password == null || password.isEmpty) {
      return 'Passwort ist erforderlich';
    }
    final result = validate(password);
    return result.isValid ? null : result.errors.first;
  }
}
```

### lib/src/phone_validator.dart

```dart
/// Validates phone numbers.
class PhoneValidator {
  static final _germanMobile = RegExp(r'^\+49\s?1[5-7]\d{1,2}\s?\d{6,8}$');
  static final _germanLandline = RegExp(r'^\+49\s?\d{2,5}\s?\d{4,10}$');
  static final _international = RegExp(r'^\+\d{1,3}\s?\d{4,14}$');

  /// Validates a German mobile phone number.
  static bool isValidGermanMobile(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[\s\-()]'), '');
    return _germanMobile.hasMatch(cleaned);
  }

  /// Validates a German landline number.
  static bool isValidGermanLandline(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[\s\-()]'), '');
    return _germanLandline.hasMatch(cleaned);
  }

  /// Validates any German phone number.
  static bool isValidGerman(String phone) {
    return isValidGermanMobile(phone) || isValidGermanLandline(phone);
  }

  /// Validates an international phone number.
  static bool isValidInternational(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[\s\-()]'), '');
    return _international.hasMatch(cleaned);
  }

  /// Form validator for German phone numbers.
  static String? validateGerman(String? phone) {
    if (phone == null || phone.isEmpty) {
      return 'Telefonnummer ist erforderlich';
    }
    if (!isValidGerman(phone)) {
      return 'Ungültige deutsche Telefonnummer';
    }
    return null;
  }
}
```

### lib/src/iban_validator.dart

```dart
/// Validates IBAN numbers.
class IbanValidator {
  static final _ibanRegex = RegExp(r'^[A-Z]{2}\d{2}[A-Z0-9]{4,30}$');

  /// Validates an IBAN (basic format check).
  static bool isValid(String iban) {
    final cleaned = iban.replaceAll(RegExp(r'\s'), '').toUpperCase();

    if (!_ibanRegex.hasMatch(cleaned)) return false;
    if (cleaned.length < 15 || cleaned.length > 34) return false;

    // Checksum validation
    return _validateChecksum(cleaned);
  }

  static bool _validateChecksum(String iban) {
    // Move first 4 chars to end
    final rearranged = iban.substring(4) + iban.substring(0, 4);

    // Convert letters to numbers (A=10, B=11, etc.)
    final numericString = rearranged.split('').map((char) {
      final code = char.codeUnitAt(0);
      if (code >= 65 && code <= 90) {
        return (code - 55).toString();
      }
      return char;
    }).join();

    // Calculate mod 97
    return _mod97(numericString) == 1;
  }

  static int _mod97(String numericString) {
    var remainder = 0;
    for (var i = 0; i < numericString.length; i++) {
      final digit = int.parse(numericString[i]);
      remainder = (remainder * 10 + digit) % 97;
    }
    return remainder;
  }

  /// Form validator for IBAN.
  static String? validate(String? iban) {
    if (iban == null || iban.isEmpty) {
      return 'IBAN ist erforderlich';
    }
    if (!isValid(iban)) {
      return 'Ungültige IBAN';
    }
    return null;
  }
}
```

### test/validators_test.dart

```dart
import 'package:test/test.dart';
import 'package:my_validators/my_validators.dart';

void main() {
  group('EmailValidator', () {
    test('validates correct emails', () {
      expect(EmailValidator.isValid('test@example.com'), isTrue);
      expect(EmailValidator.isValid('user.name@domain.co.uk'), isTrue);
    });

    test('rejects invalid emails', () {
      expect(EmailValidator.isValid('invalid'), isFalse);
      expect(EmailValidator.isValid('test@'), isFalse);
      expect(EmailValidator.isValid(''), isFalse);
    });
  });

  group('PasswordValidator', () {
    test('validates with default config', () {
      final validator = PasswordValidator();
      expect(validator.validate('Password1').isValid, isTrue);
      expect(validator.validate('weak').isValid, isFalse);
    });

    test('validates with strong config', () {
      final validator = PasswordValidator(config: PasswordConfig.strong);
      expect(validator.validate('Password1!@#').isValid, isTrue);
      expect(validator.validate('Password1').isValid, isFalse);
    });
  });

  group('PhoneValidator', () {
    test('validates German mobile', () {
      expect(PhoneValidator.isValidGermanMobile('+49 151 12345678'), isTrue);
      expect(PhoneValidator.isValidGermanMobile('invalid'), isFalse);
    });
  });

  group('IbanValidator', () {
    test('validates correct IBAN', () {
      expect(IbanValidator.isValid('DE89 3704 0044 0532 0130 00'), isTrue);
    });

    test('rejects invalid IBAN', () {
      expect(IbanValidator.isValid('DE00 0000 0000 0000 0000 00'), isFalse);
    });
  });
}
```

---

## Aufgabe 3: Widget Package

```dart
// lib/src/loading_button.dart
import 'package:flutter/material.dart';

/// A button that shows a loading indicator while processing.
class LoadingButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPressed;
  final Widget child;
  final ButtonStyle? style;

  const LoadingButton({
    super.key,
    required this.isLoading,
    required this.onPressed,
    required this.child,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: style,
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : child,
    );
  }
}

// lib/src/rating_bar.dart
import 'package:flutter/material.dart';

/// An interactive star rating widget.
class RatingBar extends StatelessWidget {
  final int rating;
  final int maxRating;
  final ValueChanged<int>? onRatingChanged;
  final double size;
  final Color activeColor;
  final Color inactiveColor;

  const RatingBar({
    super.key,
    required this.rating,
    this.maxRating = 5,
    this.onRatingChanged,
    this.size = 32,
    this.activeColor = Colors.amber,
    this.inactiveColor = Colors.grey,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxRating, (index) {
        final isActive = index < rating;
        return GestureDetector(
          onTap: onRatingChanged != null
              ? () => onRatingChanged!(index + 1)
              : null,
          child: Icon(
            isActive ? Icons.star : Icons.star_border,
            size: size,
            color: isActive ? activeColor : inactiveColor,
          ),
        );
      }),
    );
  }
}

// lib/src/expandable_text.dart
import 'package:flutter/material.dart';

/// A text widget that can be expanded to show full content.
class ExpandableText extends StatefulWidget {
  final String text;
  final int maxLines;
  final TextStyle? style;
  final String expandText;
  final String collapseText;

  const ExpandableText({
    super.key,
    required this.text,
    this.maxLines = 3,
    this.style,
    this.expandText = 'mehr anzeigen',
    this.collapseText = 'weniger anzeigen',
  });

  @override
  State<ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<ExpandableText> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textSpan = TextSpan(text: widget.text, style: widget.style);
        final textPainter = TextPainter(
          text: textSpan,
          maxLines: widget.maxLines,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: constraints.maxWidth);

        final isOverflowing = textPainter.didExceedMaxLines;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.text,
              style: widget.style,
              maxLines: _isExpanded ? null : widget.maxLines,
              overflow: _isExpanded ? null : TextOverflow.ellipsis,
            ),
            if (isOverflowing)
              GestureDetector(
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _isExpanded ? widget.collapseText : widget.expandText,
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
```

---

## Aufgabe 4: Platform Channel - Device Info

### Dart

```dart
import 'package:flutter/services.dart';

class DeviceInfoService {
  static const _channel = MethodChannel('com.example/device_info');

  Future<String> getDeviceModel() async {
    try {
      return await _channel.invokeMethod<String>('getDeviceModel') ?? 'Unknown';
    } on PlatformException {
      return 'Unknown';
    }
  }

  Future<String> getOsVersion() async {
    try {
      return await _channel.invokeMethod<String>('getOsVersion') ?? 'Unknown';
    } on PlatformException {
      return 'Unknown';
    }
  }

  Future<int> getAvailableStorage() async {
    try {
      return await _channel.invokeMethod<int>('getAvailableStorage') ?? -1;
    } on PlatformException {
      return -1;
    }
  }

  Future<bool> isEmulator() async {
    try {
      return await _channel.invokeMethod<bool>('isEmulator') ?? false;
    } on PlatformException {
      return false;
    }
  }
}
```

### Android (Kotlin)

```kotlin
package com.example.my_app

import android.os.Build
import android.os.Environment
import android.os.StatFs
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example/device_info"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getDeviceModel" -> result.success("${Build.MANUFACTURER} ${Build.MODEL}")
                    "getOsVersion" -> result.success("Android ${Build.VERSION.RELEASE}")
                    "getAvailableStorage" -> result.success(getAvailableStorageMB())
                    "isEmulator" -> result.success(isEmulator())
                    else -> result.notImplemented()
                }
            }
    }

    private fun getAvailableStorageMB(): Int {
        val stat = StatFs(Environment.getDataDirectory().path)
        val bytesAvailable = stat.blockSizeLong * stat.availableBlocksLong
        return (bytesAvailable / (1024 * 1024)).toInt()
    }

    private fun isEmulator(): Boolean {
        return Build.FINGERPRINT.contains("generic") ||
               Build.FINGERPRINT.contains("emulator") ||
               Build.MODEL.contains("Emulator") ||
               Build.MANUFACTURER.contains("Genymotion")
    }
}
```

---

## Aufgabe 6: Plattform-spezifisches UI

```dart
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Adaptive progress indicator.
class AdaptiveProgressIndicator extends StatelessWidget {
  const AdaptiveProgressIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return const CupertinoActivityIndicator();
    }
    return const CircularProgressIndicator();
  }
}

/// Adaptive switch.
class AdaptiveSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;

  const AdaptiveSwitch({
    super.key,
    required this.value,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return CupertinoSwitch(value: value, onChanged: onChanged);
    }
    return Switch(value: value, onChanged: onChanged);
  }
}

/// Adaptive list tile.
class AdaptiveListTile extends StatelessWidget {
  final Widget? leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const AdaptiveListTile({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return CupertinoListTile(
        leading: leading,
        title: title,
        subtitle: subtitle,
        trailing: trailing ?? const CupertinoListTileChevron(),
        onTap: onTap,
      );
    }
    return ListTile(
      leading: leading,
      title: title,
      subtitle: subtitle,
      trailing: trailing,
      onTap: onTap,
    );
  }
}

/// Adaptive scaffold with navigation bar.
class AdaptiveScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;

  const AdaptiveScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text(title),
          trailing: actions != null && actions!.isNotEmpty
              ? Row(mainAxisSize: MainAxisSize.min, children: actions!)
              : null,
        ),
        child: SafeArea(child: body),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: actions),
      body: body,
    );
  }
}
```
