# Übung 8.4: OAuth 2.0 & Social Login

## Ziel

Implementiere Google und GitHub Login für deine API.

---

## Vorbereitung

### Dependencies

```yaml
dependencies:
  http: ^1.1.0
  # ... bestehende Dependencies
```

### Google OAuth Setup

1. Gehe zu [Google Cloud Console](https://console.cloud.google.com)
2. Erstelle ein Projekt
3. Aktiviere "Google+ API"
4. Erstelle OAuth 2.0 Client ID (Web application)
5. Füge `http://localhost:8080/api/auth/google/callback` als Redirect URI hinzu
6. Notiere Client ID und Client Secret

### GitHub OAuth Setup

1. Gehe zu GitHub → Settings → Developer settings → OAuth Apps
2. Erstelle eine neue OAuth App
3. Callback URL: `http://localhost:8080/api/auth/github/callback`
4. Notiere Client ID und Client Secret

### Environment Variables

```bash
export GOOGLE_CLIENT_ID="your-google-client-id"
export GOOGLE_CLIENT_SECRET="your-google-client-secret"
export GITHUB_CLIENT_ID="your-github-client-id"
export GITHUB_CLIENT_SECRET="your-github-client-secret"
```

### Datenbank

```sql
CREATE TABLE oauth_accounts (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    provider VARCHAR(50) NOT NULL,
    provider_user_id VARCHAR(255) NOT NULL,
    access_token TEXT NOT NULL,
    refresh_token TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE(provider, provider_user_id)
);
```

---

## Aufgabe 1: OAuth Models (10 min)

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

  // TODO: Factory für JSON-Parsing
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
}
```

---

## Aufgabe 2: OAuth Provider Interface (10 min)

```dart
// lib/services/oauth/oauth_provider.dart

abstract class OAuthProvider {
  /// Name des Providers ('google', 'github')
  String get name;

  /// Generiere Authorization URL
  String getAuthorizationUrl({String? state});

  /// Tausche Code gegen Tokens
  Future<OAuthTokens> exchangeCode(String code);

  /// Lade User-Info
  Future<OAuthUserInfo> getUserInfo(String accessToken);
}
```

---

## Aufgabe 3: Google OAuth Provider (20 min)

```dart
// lib/services/oauth/google_oauth_provider.dart

class GoogleOAuthProvider implements OAuthProvider {
  final String clientId;
  final String clientSecret;
  final String redirectUri;

  // Endpoints
  static const authEndpoint = 'https://accounts.google.com/o/oauth2/v2/auth';
  static const tokenEndpoint = 'https://oauth2.googleapis.com/token';
  static const userInfoEndpoint = 'https://www.googleapis.com/oauth2/v2/userinfo';

  GoogleOAuthProvider({
    required this.clientId,
    required this.clientSecret,
    required this.redirectUri,
  });

  @override
  String get name => 'google';

  @override
  String getAuthorizationUrl({String? state}) {
    // TODO:
    // Query-Parameter: client_id, redirect_uri, response_type=code,
    // scope=openid email profile, access_type=offline, state
  }

  @override
  Future<OAuthTokens> exchangeCode(String code) async {
    // TODO:
    // POST zu tokenEndpoint mit:
    // client_id, client_secret, code, grant_type=authorization_code, redirect_uri
    // Response parsen und OAuthTokens zurückgeben
  }

  @override
  Future<OAuthUserInfo> getUserInfo(String accessToken) async {
    // TODO:
    // GET zu userInfoEndpoint mit Authorization: Bearer header
    // Response parsen und OAuthUserInfo zurückgeben
  }
}
```

---

## Aufgabe 4: GitHub OAuth Provider (20 min)

```dart
// lib/services/oauth/github_oauth_provider.dart

class GitHubOAuthProvider implements OAuthProvider {
  final String clientId;
  final String clientSecret;
  final String redirectUri;

  static const authEndpoint = 'https://github.com/login/oauth/authorize';
  static const tokenEndpoint = 'https://github.com/login/oauth/access_token';
  static const userInfoEndpoint = 'https://api.github.com/user';
  static const emailEndpoint = 'https://api.github.com/user/emails';

  GitHubOAuthProvider({
    required this.clientId,
    required this.clientSecret,
    required this.redirectUri,
  });

  @override
  String get name => 'github';

  @override
  String getAuthorizationUrl({String? state}) {
    // TODO: scope=read:user user:email
  }

  @override
  Future<OAuthTokens> exchangeCode(String code) async {
    // TODO: Header Accept: application/json setzen!
  }

  @override
  Future<OAuthUserInfo> getUserInfo(String accessToken) async {
    // TODO:
    // 1. User-Info laden
    // 2. Falls email null: separaten Email-Endpoint aufrufen
    // 3. Primary Email finden
  }
}
```

---

## Aufgabe 5: OAuth Account Repository (15 min)

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

  /// Finde Account nach Provider und Provider-User-ID
  Future<OAuthAccount?> findByProviderAndId(String provider, String id) async {
    // TODO
  }

  /// Erstelle neuen OAuth-Account
  Future<OAuthAccount> create(OAuthAccount account) async {
    // TODO
  }

  /// Update Tokens
  Future<void> updateTokens(int id, String accessToken, String? refreshToken) async {
    // TODO
  }

  /// Finde alle Accounts eines Users
  Future<List<OAuthAccount>> findByUserId(int userId) async {
    // TODO
  }

  /// Lösche Account
  Future<void> delete(int id) async {
    // TODO
  }
}
```

---

## Aufgabe 6: OAuth Service (25 min)

```dart
// lib/services/oauth_service.dart

class OAuthService {
  final Map<String, OAuthProvider> _providers = {};
  final UserRepository _userRepo;
  final OAuthAccountRepository _oauthRepo;
  final JwtService _jwtService;

  OAuthService({
    required UserRepository userRepo,
    required OAuthAccountRepository oauthRepo,
    required JwtService jwtService,
  })  : _userRepo = userRepo,
        _oauthRepo = oauthRepo,
        _jwtService = jwtService;

  void registerProvider(OAuthProvider provider) {
    _providers[provider.name] = provider;
  }

  OAuthProvider getProvider(String name) {
    final provider = _providers[name];
    if (provider == null) {
      throw OAuthException('Unknown provider: $name');
    }
    return provider;
  }

  /// Generiere State für CSRF-Schutz
  String generateState() {
    // TODO: Zufälligen Base64-String generieren
  }

  /// Authorization URL für Provider
  String getAuthorizationUrl(String provider, String state) {
    return getProvider(provider).getAuthorizationUrl(state: state);
  }

  /// OAuth Callback verarbeiten
  Future<TokenPair> handleCallback({
    required String provider,
    required String code,
  }) async {
    // TODO:
    // 1. Provider holen
    // 2. Code gegen Token tauschen
    // 3. User-Info laden
    // 4. User finden oder erstellen
    // 5. OAuth-Account verknüpfen/updaten
    // 6. JWT generieren
  }

  /// User finden oder erstellen
  Future<User> _findOrCreateUser(OAuthUserInfo info) async {
    // TODO:
    // 1. Prüfen ob OAuth-Account existiert → User laden
    // 2. Prüfen ob Email existiert → User zurückgeben
    // 3. Neuen User erstellen
  }

  /// OAuth-Account mit User verknüpfen
  Future<void> _linkOAuthAccount(
    int userId,
    OAuthUserInfo info,
    OAuthTokens tokens,
  ) async {
    // TODO:
    // Existierenden Account updaten oder neuen erstellen
  }
}
```

---

## Aufgabe 7: OAuth Handler (15 min)

```dart
// lib/handlers/oauth_handler.dart

class OAuthHandler {
  final OAuthService _oauthService;

  // State-Store (in Produktion: Redis mit TTL)
  final Map<String, DateTime> _stateStore = {};
  final Duration _stateTimeout = const Duration(minutes: 10);

  OAuthHandler(this._oauthService);

  Router get router {
    final router = Router();

    // GET /auth/oauth/:provider - Initiiere OAuth
    router.get('/<provider>', _initiateOAuth);

    // GET /auth/oauth/:provider/callback - Callback
    router.get('/<provider>/callback', _handleCallback);

    return router;
  }

  /// Initiiere OAuth-Flow
  Future<Response> _initiateOAuth(Request request) async {
    // TODO:
    // 1. Provider aus URL-Params
    // 2. State generieren und speichern
    // 3. Authorization URL generieren
    // 4. Redirect Response zurückgeben
  }

  /// Verarbeite Callback
  Future<Response> _handleCallback(Request request) async {
    // TODO:
    // 1. Provider, code, state, error aus Query-Params
    // 2. Error prüfen
    // 3. State validieren
    // 4. OAuth-Flow mit Service durchführen
    // 5. Token-Response oder Error zurückgeben
  }

  /// State validieren und entfernen
  bool _validateState(String state) {
    final timestamp = _stateStore.remove(state);
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) < _stateTimeout;
  }
}
```

---

## Aufgabe 8: Integration (10 min)

```dart
// bin/server.dart (Erweiterung)

// OAuth-Provider registrieren
final oauthService = OAuthService(
  userRepo: userRepo,
  oauthRepo: oauthAccountRepo,
  jwtService: jwtService,
);

oauthService.registerProvider(GoogleOAuthProvider(
  clientId: config.googleClientId,
  clientSecret: config.googleClientSecret,
  redirectUri: config.googleRedirectUri,
));

oauthService.registerProvider(GitHubOAuthProvider(
  clientId: config.githubClientId,
  clientSecret: config.githubClientSecret,
  redirectUri: config.githubRedirectUri,
));

// Handler
final oauthHandler = OAuthHandler(oauthService);

// Router erweitern
router.mount('/api/auth/oauth', oauthHandler.router);
```

---

## Testen

### Google Login starten

```bash
# Browser öffnet sich automatisch
open "http://localhost:8080/api/auth/oauth/google"

# Oder manuell
curl -v http://localhost:8080/api/auth/oauth/google
# Folge dem Location-Header zu Google
```

### GitHub Login starten

```bash
open "http://localhost:8080/api/auth/oauth/github"
```

### Nach erfolgreichem Login

```json
{
  "message": "Login successful",
  "access_token": "eyJhbGciOi...",
  "refresh_token": "eyJhbGciOi...",
  "expires_in": 900,
  "token_type": "Bearer"
}
```

---

## Bonus: Account Linking (Optional)

Erlaube authentifizierten Usern, weitere OAuth-Accounts zu verknüpfen:

```dart
// POST /api/users/me/oauth/:provider/link
Future<Response> linkOAuthAccount(Request request) async {
  final userId = getUserId(request)!;
  final provider = request.params['provider']!;

  // State generieren und zu Provider redirecten
  // Bei Callback: Account mit bestehendem User verknüpfen
}

// DELETE /api/users/me/oauth/:provider
Future<Response> unlinkOAuthAccount(Request request) async {
  final userId = getUserId(request)!;
  final provider = request.params['provider']!;

  await _oauthRepo.deleteByUserAndProvider(userId, provider);
  return Response(204);
}
```

---

## Abgabe-Checkliste

- [ ] OAuthTokens und OAuthUserInfo Models
- [ ] GoogleOAuthProvider mit allen Methoden
- [ ] GitHubOAuthProvider mit Email-Fallback
- [ ] OAuthAccountRepository
- [ ] OAuthService mit handleCallback
- [ ] State-Generierung für CSRF-Schutz
- [ ] User erstellen oder finden bei OAuth-Login
- [ ] OAuth-Account mit User verknüpfen
- [ ] OAuthHandler mit /oauth/:provider Endpoints
- [ ] State-Validierung mit Timeout
- [ ] JWT-Response nach erfolgreichem OAuth

