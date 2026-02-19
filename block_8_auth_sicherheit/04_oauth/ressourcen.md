# Ressourcen: OAuth 2.0 & Social Login

## Offizielle Dokumentation

- [OAuth 2.0 RFC 6749](https://tools.ietf.org/html/rfc6749)
- [Google OAuth Documentation](https://developers.google.com/identity/protocols/oauth2)
- [GitHub OAuth Documentation](https://docs.github.com/en/developers/apps/building-oauth-apps)
- [OWASP OAuth Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/OAuth_Cheat_Sheet.html)

## Cheat Sheet: OAuth 2.0 Flows

| Flow | Verwendung | Sicherheit |
|------|------------|------------|
| **Authorization Code** | Server-Apps | Hoch |
| Authorization Code + PKCE | Mobile/SPA | Hoch |
| Implicit | Legacy SPAs | Niedrig (veraltet) |
| Client Credentials | Server-to-Server | Hoch |
| Resource Owner Password | Legacy | Niedrig |

## Cheat Sheet: Authorization Code Flow

```
1. Client → Auth Server: GET /authorize
   ?client_id=...
   &redirect_uri=...
   &response_type=code
   &scope=...
   &state=...

2. User authentifiziert sich

3. Auth Server → Client: Redirect
   ?code=...
   &state=...

4. Client → Auth Server: POST /token
   client_id=...
   &client_secret=...
   &code=...
   &grant_type=authorization_code

5. Auth Server → Client: Access Token
```

## Cheat Sheet: Google OAuth

```dart
// Endpoints
const authEndpoint = 'https://accounts.google.com/o/oauth2/v2/auth';
const tokenEndpoint = 'https://oauth2.googleapis.com/token';
const userInfoEndpoint = 'https://www.googleapis.com/oauth2/v2/userinfo';

// Authorization URL
final authUrl = Uri.parse(authEndpoint).replace(queryParameters: {
  'client_id': clientId,
  'redirect_uri': redirectUri,
  'response_type': 'code',
  'scope': 'openid email profile',
  'access_type': 'offline',  // Für Refresh Token
  'prompt': 'consent',       // Immer Consent-Screen zeigen
  'state': state,
});

// Token Exchange
final response = await http.post(Uri.parse(tokenEndpoint), body: {
  'client_id': clientId,
  'client_secret': clientSecret,
  'code': code,
  'grant_type': 'authorization_code',
  'redirect_uri': redirectUri,
});

// User Info
final response = await http.get(
  Uri.parse(userInfoEndpoint),
  headers: {'Authorization': 'Bearer $accessToken'},
);
```

## Cheat Sheet: GitHub OAuth

```dart
// Endpoints
const authEndpoint = 'https://github.com/login/oauth/authorize';
const tokenEndpoint = 'https://github.com/login/oauth/access_token';
const userInfoEndpoint = 'https://api.github.com/user';
const emailEndpoint = 'https://api.github.com/user/emails';

// Wichtig: Accept: application/json für Token-Request!
final response = await http.post(Uri.parse(tokenEndpoint),
  headers: {'Accept': 'application/json'},
  body: {
    'client_id': clientId,
    'client_secret': clientSecret,
    'code': code,
  },
);

// User Info (GitHub-spezifischer Accept-Header)
final response = await http.get(
  Uri.parse(userInfoEndpoint),
  headers: {
    'Authorization': 'Bearer $accessToken',
    'Accept': 'application/vnd.github.v3+json',
  },
);
```

## Cheat Sheet: State Parameter (CSRF-Schutz)

```dart
// State generieren
String generateState() {
  final random = Random.secure();
  final values = List<int>.generate(32, (_) => random.nextInt(256));
  return base64Url.encode(values);
}

// State speichern (mit Timeout)
final stateStore = <String, DateTime>{};
stateStore[state] = DateTime.now();

// State validieren
bool validateState(String state) {
  final timestamp = stateStore.remove(state);
  if (timestamp == null) return false;
  return DateTime.now().difference(timestamp) < Duration(minutes: 10);
}
```

## Cheat Sheet: Scopes

### Google

| Scope | Beschreibung |
|-------|--------------|
| `openid` | OpenID Connect |
| `email` | Email-Adresse |
| `profile` | Basis-Profil |
| `https://www.googleapis.com/auth/calendar` | Kalender |
| `https://www.googleapis.com/auth/drive` | Drive |

### GitHub

| Scope | Beschreibung |
|-------|--------------|
| `read:user` | Profil lesen |
| `user:email` | Email lesen |
| `repo` | Repositories |
| `gist` | Gists |

## Best Practices

### DO

1. **State Parameter** - Immer für CSRF-Schutz
2. **HTTPS** - OAuth nur über HTTPS
3. **Redirect URI validieren** - Exakte Match
4. **Secrets serverseitig** - Nie im Client
5. **Tokens sicher speichern** - Verschlüsselt in DB
6. **Minimale Scopes** - Nur nötige anfordern

### DON'T

1. **Client Secret im Frontend** - Nie!
2. **State wiederverwenden** - Immer neu generieren
3. **Implicit Flow** - Veraltet und unsicher
4. **Unvalidierte Redirects** - Open Redirect Vulnerability
5. **Tokens im URL-Parameter** - Log-Leaks

## SQL Schema

```sql
CREATE TABLE oauth_accounts (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    provider VARCHAR(50) NOT NULL,
    provider_user_id VARCHAR(255) NOT NULL,
    access_token TEXT NOT NULL,
    refresh_token TEXT,
    token_expires_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP,
    UNIQUE(provider, provider_user_id)
);

CREATE INDEX idx_oauth_user ON oauth_accounts(user_id);
CREATE INDEX idx_oauth_provider ON oauth_accounts(provider, provider_user_id);
```

## Provider Setup URLs

| Provider | Console URL |
|----------|-------------|
| Google | https://console.cloud.google.com/apis/credentials |
| GitHub | https://github.com/settings/developers |
| Microsoft | https://portal.azure.com/#blade/Microsoft_AAD_RegisteredApps |
| Facebook | https://developers.facebook.com/apps |
| Apple | https://developer.apple.com/account/resources/identifiers |

