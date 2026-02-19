# Einheit 8.4: OAuth 2.0 & Social Login

## Lernziele

Nach dieser Einheit kannst du:
- OAuth 2.0 Flows verstehen und implementieren
- Google und GitHub Login integrieren
- Token-Exchange durchführen
- OAuth-Provider in deine API einbinden

---

## Was ist OAuth 2.0?

**OAuth 2.0** ist ein Autorisierungsframework, das Drittanwendungen begrenzten Zugriff auf Benutzerressourcen ermöglicht, ohne Passwörter zu teilen.

### Begriffe

| Begriff | Beschreibung |
|---------|--------------|
| **Resource Owner** | Der Benutzer |
| **Client** | Deine Anwendung |
| **Authorization Server** | Google, GitHub, etc. |
| **Resource Server** | API mit geschützten Daten |
| **Access Token** | Erlaubt Zugriff auf Ressourcen |
| **Refresh Token** | Zum Erneuern des Access Tokens |

### OAuth vs. Eigene Auth

| Eigene Auth | OAuth/Social Login |
|-------------|-------------------|
| Volle Kontrolle | Delegiert an Provider |
| Passwort-Verwaltung nötig | Keine Passwörter |
| Mehr Entwicklungsaufwand | Schnelle Integration |
| Nur eigene Accounts | Millionen existierende Accounts |

---

## OAuth 2.0 Flows

### Authorization Code Flow (empfohlen für Server)

```
1. User klickt "Login mit Google"
2. Redirect zu Google Authorization URL
3. User gibt Zustimmung bei Google
4. Google redirected zurück mit Authorization Code
5. Backend tauscht Code gegen Access Token
6. Backend lädt User-Info von Google
7. Backend erstellt/aktualisiert User und gibt eigenen JWT aus
```

```
┌──────────┐     ┌─────────────┐     ┌──────────┐
│  Client  │     │   Backend   │     │  Google  │
└────┬─────┘     └──────┬──────┘     └────┬─────┘
     │                  │                  │
     │ 1. /auth/google  │                  │
     ├─────────────────>│                  │
     │                  │                  │
     │ 2. Redirect URL  │                  │
     │<─────────────────┤                  │
     │                  │                  │
     │ 3. Redirect to Google               │
     ├────────────────────────────────────>│
     │                  │                  │
     │ 4. User Login & Consent             │
     │<────────────────────────────────────┤
     │                  │                  │
     │ 5. Redirect with Code               │
     ├─────────────────>│                  │
     │                  │                  │
     │                  │ 6. Exchange Code │
     │                  ├─────────────────>│
     │                  │                  │
     │                  │ 7. Access Token  │
     │                  │<─────────────────┤
     │                  │                  │
     │                  │ 8. Get User Info │
     │                  ├─────────────────>│
     │                  │                  │
     │                  │ 9. User Data     │
     │                  │<─────────────────┤
     │                  │                  │
     │ 10. JWT Token    │                  │
     │<─────────────────┤                  │
```

---

## Google OAuth Setup

### 1. Google Cloud Console

1. Gehe zu [Google Cloud Console](https://console.cloud.google.com)
2. Neues Projekt erstellen
3. APIs & Services → OAuth consent screen
4. APIs & Services → Credentials → OAuth 2.0 Client IDs
5. Client ID und Client Secret notieren

### 2. Konfiguration

```dart
// lib/config/oauth_config.dart

class OAuthConfig {
  final String googleClientId;
  final String googleClientSecret;
  final String googleRedirectUri;

  final String githubClientId;
  final String githubClientSecret;
  final String githubRedirectUri;

  OAuthConfig({
    required this.googleClientId,
    required this.googleClientSecret,
    required this.googleRedirectUri,
    required this.githubClientId,
    required this.githubClientSecret,
    required this.githubRedirectUri,
  });

  factory OAuthConfig.fromEnvironment() {
    return OAuthConfig(
      googleClientId: Platform.environment['GOOGLE_CLIENT_ID'] ?? '',
      googleClientSecret: Platform.environment['GOOGLE_CLIENT_SECRET'] ?? '',
      googleRedirectUri: Platform.environment['GOOGLE_REDIRECT_URI'] ??
          'http://localhost:8080/api/auth/google/callback',
      githubClientId: Platform.environment['GITHUB_CLIENT_ID'] ?? '',
      githubClientSecret: Platform.environment['GITHUB_CLIENT_SECRET'] ?? '',
      githubRedirectUri: Platform.environment['GITHUB_REDIRECT_URI'] ??
          'http://localhost:8080/api/auth/github/callback',
    );
  }
}
```

---

## Google OAuth Provider

```dart
// lib/services/oauth/google_oauth_provider.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class GoogleOAuthProvider {
  final String clientId;
  final String clientSecret;
  final String redirectUri;

  static const authorizationEndpoint = 'https://accounts.google.com/o/oauth2/v2/auth';
  static const tokenEndpoint = 'https://oauth2.googleapis.com/token';
  static const userInfoEndpoint = 'https://www.googleapis.com/oauth2/v2/userinfo';

  GoogleOAuthProvider({
    required this.clientId,
    required this.clientSecret,
    required this.redirectUri,
  });

  /// Generiere Authorization URL
  String getAuthorizationUrl({String? state}) {
    final params = {
      'client_id': clientId,
      'redirect_uri': redirectUri,
      'response_type': 'code',
      'scope': 'openid email profile',
      'access_type': 'offline', // Für Refresh Token
      'prompt': 'consent',
      if (state != null) 'state': state,
    };

    return Uri.parse(authorizationEndpoint)
        .replace(queryParameters: params)
        .toString();
  }

  /// Tausche Authorization Code gegen Access Token
  Future<OAuthTokens> exchangeCode(String code) async {
    final response = await http.post(
      Uri.parse(tokenEndpoint),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'client_id': clientId,
        'client_secret': clientSecret,
        'code': code,
        'grant_type': 'authorization_code',
        'redirect_uri': redirectUri,
      },
    );

    if (response.statusCode != 200) {
      throw OAuthException('Token exchange failed: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    return OAuthTokens(
      accessToken: data['access_token'] as String,
      refreshToken: data['refresh_token'] as String?,
      expiresIn: data['expires_in'] as int?,
      idToken: data['id_token'] as String?,
    );
  }

  /// Lade User-Info mit Access Token
  Future<OAuthUserInfo> getUserInfo(String accessToken) async {
    final response = await http.get(
      Uri.parse(userInfoEndpoint),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode != 200) {
      throw OAuthException('Failed to get user info: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    return OAuthUserInfo(
      id: data['id'] as String,
      email: data['email'] as String,
      name: data['name'] as String?,
      picture: data['picture'] as String?,
      provider: 'google',
    );
  }
}
```

---

## GitHub OAuth Provider

```dart
// lib/services/oauth/github_oauth_provider.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class GitHubOAuthProvider {
  final String clientId;
  final String clientSecret;
  final String redirectUri;

  static const authorizationEndpoint = 'https://github.com/login/oauth/authorize';
  static const tokenEndpoint = 'https://github.com/login/oauth/access_token';
  static const userInfoEndpoint = 'https://api.github.com/user';
  static const emailEndpoint = 'https://api.github.com/user/emails';

  GitHubOAuthProvider({
    required this.clientId,
    required this.clientSecret,
    required this.redirectUri,
  });

  String getAuthorizationUrl({String? state}) {
    final params = {
      'client_id': clientId,
      'redirect_uri': redirectUri,
      'scope': 'read:user user:email',
      if (state != null) 'state': state,
    };

    return Uri.parse(authorizationEndpoint)
        .replace(queryParameters: params)
        .toString();
  }

  Future<OAuthTokens> exchangeCode(String code) async {
    final response = await http.post(
      Uri.parse(tokenEndpoint),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'application/json',
      },
      body: {
        'client_id': clientId,
        'client_secret': clientSecret,
        'code': code,
        'redirect_uri': redirectUri,
      },
    );

    if (response.statusCode != 200) {
      throw OAuthException('Token exchange failed: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (data.containsKey('error')) {
      throw OAuthException('OAuth error: ${data['error_description']}');
    }

    return OAuthTokens(
      accessToken: data['access_token'] as String,
      refreshToken: null, // GitHub doesn't provide refresh tokens
      expiresIn: null,
    );
  }

  Future<OAuthUserInfo> getUserInfo(String accessToken) async {
    // User-Info laden
    final userResponse = await http.get(
      Uri.parse(userInfoEndpoint),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Accept': 'application/vnd.github.v3+json',
      },
    );

    if (userResponse.statusCode != 200) {
      throw OAuthException('Failed to get user info');
    }

    final userData = jsonDecode(userResponse.body) as Map<String, dynamic>;

    // Email kann in User-Info null sein - dann separat laden
    String? email = userData['email'] as String?;

    if (email == null) {
      final emailResponse = await http.get(
        Uri.parse(emailEndpoint),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Accept': 'application/vnd.github.v3+json',
        },
      );

      if (emailResponse.statusCode == 200) {
        final emails = jsonDecode(emailResponse.body) as List;
        final primaryEmail = emails.firstWhere(
          (e) => e['primary'] == true,
          orElse: () => emails.isNotEmpty ? emails.first : null,
        );
        email = primaryEmail?['email'] as String?;
      }
    }

    return OAuthUserInfo(
      id: userData['id'].toString(),
      email: email ?? '',
      name: userData['name'] as String? ?? userData['login'] as String?,
      picture: userData['avatar_url'] as String?,
      provider: 'github',
    );
  }
}
```

---

## OAuth Models

```dart
// lib/models/oauth_models.dart

class OAuthTokens {
  final String accessToken;
  final String? refreshToken;
  final int? expiresIn;
  final String? idToken;

  OAuthTokens({
    required this.accessToken,
    this.refreshToken,
    this.expiresIn,
    this.idToken,
  });
}

class OAuthUserInfo {
  final String id;
  final String email;
  final String? name;
  final String? picture;
  final String provider;

  OAuthUserInfo({
    required this.id,
    required this.email,
    this.name,
    this.picture,
    required this.provider,
  });
}

class OAuthException implements Exception {
  final String message;
  OAuthException(this.message);

  @override
  String toString() => message;
}
```

---

## OAuth Service

```dart
// lib/services/oauth_service.dart

class OAuthService {
  final GoogleOAuthProvider _google;
  final GitHubOAuthProvider _github;
  final UserRepository _userRepo;
  final OAuthAccountRepository _oauthRepo;
  final JwtService _jwtService;

  OAuthService({
    required GoogleOAuthProvider google,
    required GitHubOAuthProvider github,
    required UserRepository userRepo,
    required OAuthAccountRepository oauthRepo,
    required JwtService jwtService,
  })  : _google = google,
        _github = github,
        _userRepo = userRepo,
        _oauthRepo = oauthRepo,
        _jwtService = jwtService;

  /// Generiere State-Token für CSRF-Schutz
  String generateState() {
    final random = Random.secure();
    final values = List<int>.generate(32, (_) => random.nextInt(256));
    return base64Url.encode(values);
  }

  /// Authorization URL für Provider
  String getAuthorizationUrl(String provider, String state) {
    switch (provider) {
      case 'google':
        return _google.getAuthorizationUrl(state: state);
      case 'github':
        return _github.getAuthorizationUrl(state: state);
      default:
        throw OAuthException('Unknown provider: $provider');
    }
  }

  /// OAuth Callback verarbeiten
  Future<TokenPair> handleCallback({
    required String provider,
    required String code,
  }) async {
    // 1. Code gegen Token tauschen
    OAuthTokens tokens;
    OAuthUserInfo userInfo;

    switch (provider) {
      case 'google':
        tokens = await _google.exchangeCode(code);
        userInfo = await _google.getUserInfo(tokens.accessToken);
        break;
      case 'github':
        tokens = await _github.exchangeCode(code);
        userInfo = await _github.getUserInfo(tokens.accessToken);
        break;
      default:
        throw OAuthException('Unknown provider: $provider');
    }

    // 2. User finden oder erstellen
    final user = await _findOrCreateUser(userInfo);

    // 3. OAuth-Account verknüpfen
    await _linkOAuthAccount(user.id!, userInfo, tokens);

    // 4. Eigenen JWT generieren
    return _jwtService.generateTokenPair(user);
  }

  Future<User> _findOrCreateUser(OAuthUserInfo info) async {
    // Prüfen ob OAuth-Account existiert
    final oauthAccount = await _oauthRepo.findByProviderAndId(
      info.provider,
      info.id,
    );

    if (oauthAccount != null) {
      // User existiert
      final user = await _userRepo.findById(oauthAccount.userId);
      if (user != null) return user;
    }

    // Prüfen ob Email schon existiert
    var user = await _userRepo.findByEmail(info.email);

    if (user != null) {
      return user;
    }

    // Neuen User erstellen
    user = User(
      email: info.email,
      passwordHash: '', // Kein Passwort bei OAuth
      name: info.name,
      isActive: true,
    );

    return await _userRepo.create(user);
  }

  Future<void> _linkOAuthAccount(
    int userId,
    OAuthUserInfo info,
    OAuthTokens tokens,
  ) async {
    final existing = await _oauthRepo.findByProviderAndId(
      info.provider,
      info.id,
    );

    if (existing != null) {
      // Update tokens
      await _oauthRepo.updateTokens(
        existing.id!,
        tokens.accessToken,
        tokens.refreshToken,
      );
    } else {
      // Neue Verknüpfung
      await _oauthRepo.create(OAuthAccount(
        userId: userId,
        provider: info.provider,
        providerUserId: info.id,
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
      ));
    }
  }
}
```

---

## OAuth Handler

```dart
// lib/handlers/oauth_handler.dart
import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

class OAuthHandler {
  final OAuthService _oauthService;
  final Map<String, String> _stateStore = {}; // In Produktion: Redis

  OAuthHandler(this._oauthService);

  Router get router {
    final router = Router();

    // Initiiere OAuth Flow
    router.get('/<provider>', _initiateOAuth);

    // Callback von Provider
    router.get('/<provider>/callback', _handleCallback);

    return router;
  }

  Future<Response> _initiateOAuth(Request request) async {
    final provider = request.params['provider']!;

    // State generieren und speichern
    final state = _oauthService.generateState();
    _stateStore[state] = DateTime.now().toIso8601String();

    // Redirect URL generieren
    final authUrl = _oauthService.getAuthorizationUrl(provider, state);

    // Redirect zum Provider
    return Response.found(authUrl);
  }

  Future<Response> _handleCallback(Request request) async {
    final provider = request.params['provider']!;
    final code = request.url.queryParameters['code'];
    final state = request.url.queryParameters['state'];
    final error = request.url.queryParameters['error'];

    // Error vom Provider
    if (error != null) {
      return _errorRedirect('OAuth error: $error');
    }

    // Code fehlt
    if (code == null) {
      return _errorRedirect('No authorization code received');
    }

    // State validieren (CSRF-Schutz)
    if (state == null || !_stateStore.containsKey(state)) {
      return _errorRedirect('Invalid state parameter');
    }
    _stateStore.remove(state);

    try {
      // OAuth Flow abschließen
      final tokens = await _oauthService.handleCallback(
        provider: provider,
        code: code,
      );

      // Redirect mit Tokens (oder zu Frontend mit Tokens)
      // Option 1: JSON Response
      return Response.ok(
        jsonEncode({
          'message': 'Login successful',
          ...tokens.toJson(),
        }),
        headers: {'content-type': 'application/json'},
      );

      // Option 2: Redirect zum Frontend mit Token als Fragment
      // return Response.found(
      //   'https://myapp.com/auth/callback#access_token=${tokens.accessToken}',
      // );
    } on OAuthException catch (e) {
      return _errorRedirect(e.message);
    } catch (e) {
      return _errorRedirect('OAuth failed');
    }
  }

  Response _errorRedirect(String message) {
    return Response(
      400,
      body: jsonEncode({'error': message}),
      headers: {'content-type': 'application/json'},
    );
  }
}
```

---

## OAuth Account Repository

```dart
// lib/repositories/oauth_account_repository.dart

class OAuthAccount {
  final int? id;
  final int userId;
  final String provider;
  final String providerUserId;
  final String accessToken;
  final String? refreshToken;
  final DateTime createdAt;

  OAuthAccount({
    this.id,
    required this.userId,
    required this.provider,
    required this.providerUserId,
    required this.accessToken,
    this.refreshToken,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}

class OAuthAccountRepository {
  final Connection _db;

  OAuthAccountRepository(this._db);

  Future<OAuthAccount?> findByProviderAndId(String provider, String id) async {
    final result = await _db.execute(
      Sql.named('''
        SELECT * FROM oauth_accounts
        WHERE provider = @provider AND provider_user_id = @id
      '''),
      parameters: {'provider': provider, 'id': id},
    );

    if (result.isEmpty) return null;
    return _mapToAccount(result.first.toColumnMap());
  }

  Future<OAuthAccount> create(OAuthAccount account) async {
    final result = await _db.execute(
      Sql.named('''
        INSERT INTO oauth_accounts
          (user_id, provider, provider_user_id, access_token, refresh_token)
        VALUES
          (@userId, @provider, @providerId, @accessToken, @refreshToken)
        RETURNING *
      '''),
      parameters: {
        'userId': account.userId,
        'provider': account.provider,
        'providerId': account.providerUserId,
        'accessToken': account.accessToken,
        'refreshToken': account.refreshToken,
      },
    );

    return _mapToAccount(result.first.toColumnMap());
  }

  Future<void> updateTokens(int id, String accessToken, String? refreshToken) async {
    await _db.execute(
      Sql.named('''
        UPDATE oauth_accounts
        SET access_token = @accessToken, refresh_token = @refreshToken
        WHERE id = @id
      '''),
      parameters: {
        'id': id,
        'accessToken': accessToken,
        'refreshToken': refreshToken,
      },
    );
  }

  OAuthAccount _mapToAccount(Map<String, dynamic> row) {
    return OAuthAccount(
      id: row['id'] as int,
      userId: row['user_id'] as int,
      provider: row['provider'] as String,
      providerUserId: row['provider_user_id'] as String,
      accessToken: row['access_token'] as String,
      refreshToken: row['refresh_token'] as String?,
      createdAt: row['created_at'] as DateTime,
    );
  }
}
```

---

## Datenbank-Schema

```sql
-- migrations/003_create_oauth_accounts.sql

CREATE TABLE oauth_accounts (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    provider VARCHAR(50) NOT NULL,  -- 'google', 'github', etc.
    provider_user_id VARCHAR(255) NOT NULL,
    access_token TEXT NOT NULL,
    refresh_token TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP,

    UNIQUE(provider, provider_user_id)
);

CREATE INDEX idx_oauth_accounts_user ON oauth_accounts(user_id);
CREATE INDEX idx_oauth_accounts_provider ON oauth_accounts(provider, provider_user_id);
```

---

## Zusammenfassung

| Konzept | Beschreibung |
|---------|--------------|
| **OAuth 2.0** | Autorisierungsframework für Drittanbieter-Login |
| **Authorization Code Flow** | Sicherer Flow für Server-Anwendungen |
| **State Parameter** | CSRF-Schutz bei OAuth |
| **Token Exchange** | Code gegen Access Token tauschen |
| **Provider** | Google, GitHub, Facebook, etc. |

