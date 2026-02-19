# Lösung 8.4: OAuth 2.0 & Social Login

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

  factory OAuthTokens.fromJson(Map<String, dynamic> json) {
    return OAuthTokens(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String?,
      expiresIn: json['expires_in'] as int?,
      idToken: json['id_token'] as String?,
    );
  }
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

  @override
  String toString() =>
      'OAuthUserInfo(id: $id, email: $email, name: $name, provider: $provider)';
}

class OAuthException implements Exception {
  final String message;
  final int? statusCode;

  OAuthException(this.message, {this.statusCode});

  @override
  String toString() => 'OAuthException: $message';
}
```

---

## OAuth Provider Interface

```dart
// lib/services/oauth/oauth_provider.dart

abstract class OAuthProvider {
  String get name;
  String getAuthorizationUrl({String? state});
  Future<OAuthTokens> exchangeCode(String code);
  Future<OAuthUserInfo> getUserInfo(String accessToken);
}
```

---

## Google OAuth Provider

```dart
// lib/services/oauth/google_oauth_provider.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/oauth_models.dart';
import 'oauth_provider.dart';

class GoogleOAuthProvider implements OAuthProvider {
  final String clientId;
  final String clientSecret;
  final String redirectUri;

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
    final params = <String, String>{
      'client_id': clientId,
      'redirect_uri': redirectUri,
      'response_type': 'code',
      'scope': 'openid email profile',
      'access_type': 'offline',
      'prompt': 'consent',
    };

    if (state != null) {
      params['state'] = state;
    }

    return Uri.parse(authEndpoint)
        .replace(queryParameters: params)
        .toString();
  }

  @override
  Future<OAuthTokens> exchangeCode(String code) async {
    final response = await http.post(
      Uri.parse(tokenEndpoint),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'client_id': clientId,
        'client_secret': clientSecret,
        'code': code,
        'grant_type': 'authorization_code',
        'redirect_uri': redirectUri,
      },
    );

    if (response.statusCode != 200) {
      final error = _parseError(response.body);
      throw OAuthException(
        'Google token exchange failed: $error',
        statusCode: response.statusCode,
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return OAuthTokens.fromJson(data);
  }

  @override
  Future<OAuthUserInfo> getUserInfo(String accessToken) async {
    final response = await http.get(
      Uri.parse(userInfoEndpoint),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode != 200) {
      throw OAuthException(
        'Failed to get Google user info',
        statusCode: response.statusCode,
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    return OAuthUserInfo(
      id: data['id'] as String,
      email: data['email'] as String,
      name: data['name'] as String?,
      picture: data['picture'] as String?,
      provider: name,
    );
  }

  String _parseError(String body) {
    try {
      final data = jsonDecode(body) as Map<String, dynamic>;
      return data['error_description'] as String? ??
          data['error'] as String? ??
          body;
    } catch (e) {
      return body;
    }
  }
}
```

---

## GitHub OAuth Provider

```dart
// lib/services/oauth/github_oauth_provider.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/oauth_models.dart';
import 'oauth_provider.dart';

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
    final params = <String, String>{
      'client_id': clientId,
      'redirect_uri': redirectUri,
      'scope': 'read:user user:email',
    };

    if (state != null) {
      params['state'] = state;
    }

    return Uri.parse(authEndpoint)
        .replace(queryParameters: params)
        .toString();
  }

  @override
  Future<OAuthTokens> exchangeCode(String code) async {
    final response = await http.post(
      Uri.parse(tokenEndpoint),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'application/json', // Wichtig für JSON-Response
      },
      body: {
        'client_id': clientId,
        'client_secret': clientSecret,
        'code': code,
        'redirect_uri': redirectUri,
      },
    );

    if (response.statusCode != 200) {
      throw OAuthException(
        'GitHub token exchange failed',
        statusCode: response.statusCode,
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (data.containsKey('error')) {
      throw OAuthException(
        data['error_description'] as String? ?? data['error'] as String,
      );
    }

    return OAuthTokens(
      accessToken: data['access_token'] as String,
      refreshToken: null, // GitHub provides no refresh tokens
      expiresIn: null,
    );
  }

  @override
  Future<OAuthUserInfo> getUserInfo(String accessToken) async {
    // 1. User-Info laden
    final userResponse = await http.get(
      Uri.parse(userInfoEndpoint),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Accept': 'application/vnd.github.v3+json',
      },
    );

    if (userResponse.statusCode != 200) {
      throw OAuthException(
        'Failed to get GitHub user info',
        statusCode: userResponse.statusCode,
      );
    }

    final userData = jsonDecode(userResponse.body) as Map<String, dynamic>;

    // 2. Email (kann in User-Daten null sein)
    String? email = userData['email'] as String?;

    if (email == null || email.isEmpty) {
      email = await _getPrimaryEmail(accessToken);
    }

    if (email == null || email.isEmpty) {
      throw OAuthException('Could not retrieve email from GitHub');
    }

    return OAuthUserInfo(
      id: userData['id'].toString(),
      email: email,
      name: userData['name'] as String? ?? userData['login'] as String?,
      picture: userData['avatar_url'] as String?,
      provider: name,
    );
  }

  Future<String?> _getPrimaryEmail(String accessToken) async {
    final response = await http.get(
      Uri.parse(emailEndpoint),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Accept': 'application/vnd.github.v3+json',
      },
    );

    if (response.statusCode != 200) {
      return null;
    }

    final emails = jsonDecode(response.body) as List<dynamic>;

    // Primäre Email suchen
    for (final email in emails) {
      if (email['primary'] == true && email['verified'] == true) {
        return email['email'] as String;
      }
    }

    // Fallback: Erste verifizierte Email
    for (final email in emails) {
      if (email['verified'] == true) {
        return email['email'] as String;
      }
    }

    // Fallback: Erste Email
    if (emails.isNotEmpty) {
      return emails.first['email'] as String;
    }

    return null;
  }
}
```

---

## OAuth Account Repository

```dart
// lib/repositories/oauth_account_repository.dart
import 'package:postgres/postgres.dart';

class OAuthAccount {
  final int? id;
  final int userId;
  final String provider;
  final String providerUserId;
  final String accessToken;
  final String? refreshToken;
  final DateTime createdAt;
  final DateTime? updatedAt;

  OAuthAccount({
    this.id,
    required this.userId,
    required this.provider,
    required this.providerUserId,
    required this.accessToken,
    this.refreshToken,
    DateTime? createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory OAuthAccount.fromRow(Map<String, dynamic> row) {
    return OAuthAccount(
      id: row['id'] as int,
      userId: row['user_id'] as int,
      provider: row['provider'] as String,
      providerUserId: row['provider_user_id'] as String,
      accessToken: row['access_token'] as String,
      refreshToken: row['refresh_token'] as String?,
      createdAt: row['created_at'] as DateTime,
      updatedAt: row['updated_at'] as DateTime?,
    );
  }
}

class OAuthAccountRepository {
  final Connection _db;

  OAuthAccountRepository(this._db);

  Future<OAuthAccount?> findByProviderAndId(String provider, String providerUserId) async {
    final result = await _db.execute(
      Sql.named('''
        SELECT * FROM oauth_accounts
        WHERE provider = @provider AND provider_user_id = @providerUserId
      '''),
      parameters: {
        'provider': provider,
        'providerUserId': providerUserId,
      },
    );

    if (result.isEmpty) return null;
    return OAuthAccount.fromRow(result.first.toColumnMap());
  }

  Future<OAuthAccount> create(OAuthAccount account) async {
    final result = await _db.execute(
      Sql.named('''
        INSERT INTO oauth_accounts
          (user_id, provider, provider_user_id, access_token, refresh_token)
        VALUES
          (@userId, @provider, @providerUserId, @accessToken, @refreshToken)
        RETURNING *
      '''),
      parameters: {
        'userId': account.userId,
        'provider': account.provider,
        'providerUserId': account.providerUserId,
        'accessToken': account.accessToken,
        'refreshToken': account.refreshToken,
      },
    );

    return OAuthAccount.fromRow(result.first.toColumnMap());
  }

  Future<void> updateTokens(int id, String accessToken, String? refreshToken) async {
    await _db.execute(
      Sql.named('''
        UPDATE oauth_accounts
        SET access_token = @accessToken,
            refresh_token = @refreshToken,
            updated_at = NOW()
        WHERE id = @id
      '''),
      parameters: {
        'id': id,
        'accessToken': accessToken,
        'refreshToken': refreshToken,
      },
    );
  }

  Future<List<OAuthAccount>> findByUserId(int userId) async {
    final result = await _db.execute(
      Sql.named('SELECT * FROM oauth_accounts WHERE user_id = @userId'),
      parameters: {'userId': userId},
    );

    return result.map((row) => OAuthAccount.fromRow(row.toColumnMap())).toList();
  }

  Future<void> delete(int id) async {
    await _db.execute(
      Sql.named('DELETE FROM oauth_accounts WHERE id = @id'),
      parameters: {'id': id},
    );
  }

  Future<void> deleteByUserAndProvider(int userId, String provider) async {
    await _db.execute(
      Sql.named('''
        DELETE FROM oauth_accounts
        WHERE user_id = @userId AND provider = @provider
      '''),
      parameters: {'userId': userId, 'provider': provider},
    );
  }
}
```

---

## OAuth Service

```dart
// lib/services/oauth_service.dart
import 'dart:convert';
import 'dart:math';
import '../models/oauth_models.dart';
import '../models/user.dart';
import '../models/token_pair.dart';
import '../repositories/user_repository.dart';
import '../repositories/oauth_account_repository.dart';
import 'jwt_service.dart';
import 'oauth/oauth_provider.dart';

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
      throw OAuthException('Unknown OAuth provider: $name');
    }
    return provider;
  }

  List<String> get availableProviders => _providers.keys.toList();

  String generateState() {
    final random = Random.secure();
    final values = List<int>.generate(32, (_) => random.nextInt(256));
    return base64Url.encode(values);
  }

  String getAuthorizationUrl(String provider, String state) {
    return getProvider(provider).getAuthorizationUrl(state: state);
  }

  Future<TokenPair> handleCallback({
    required String provider,
    required String code,
  }) async {
    final oauthProvider = getProvider(provider);

    // 1. Code gegen Token tauschen
    final tokens = await oauthProvider.exchangeCode(code);

    // 2. User-Info laden
    final userInfo = await oauthProvider.getUserInfo(tokens.accessToken);

    // 3. User finden oder erstellen
    final user = await _findOrCreateUser(userInfo);

    // 4. OAuth-Account verknüpfen
    await _linkOAuthAccount(user.id!, userInfo, tokens);

    // 5. JWT generieren
    return _jwtService.generateTokenPair(user);
  }

  Future<User> _findOrCreateUser(OAuthUserInfo info) async {
    // 1. Prüfen ob OAuth-Account existiert
    final existingOAuth = await _oauthRepo.findByProviderAndId(
      info.provider,
      info.id,
    );

    if (existingOAuth != null) {
      final user = await _userRepo.findById(existingOAuth.userId);
      if (user != null) return user;
    }

    // 2. Prüfen ob Email schon existiert
    final existingUser = await _userRepo.findByEmail(info.email.toLowerCase());
    if (existingUser != null) {
      return existingUser;
    }

    // 3. Neuen User erstellen
    final newUser = User(
      email: info.email.toLowerCase(),
      passwordHash: '', // Kein Passwort bei OAuth
      name: info.name,
      isActive: true,
      role: 'user',
    );

    return await _userRepo.create(newUser);
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
      // Neue Verknüpfung erstellen
      await _oauthRepo.create(OAuthAccount(
        userId: userId,
        provider: info.provider,
        providerUserId: info.id,
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
      ));
    }
  }

  /// Verknüpfe OAuth-Account mit bestehendem User
  Future<void> linkAccountToUser({
    required int userId,
    required String provider,
    required String code,
  }) async {
    final oauthProvider = getProvider(provider);

    final tokens = await oauthProvider.exchangeCode(code);
    final userInfo = await oauthProvider.getUserInfo(tokens.accessToken);

    // Prüfen ob Account schon verknüpft ist
    final existing = await _oauthRepo.findByProviderAndId(
      provider,
      userInfo.id,
    );

    if (existing != null && existing.userId != userId) {
      throw OAuthException('This account is already linked to another user');
    }

    await _linkOAuthAccount(userId, userInfo, tokens);
  }

  /// Entferne OAuth-Account-Verknüpfung
  Future<void> unlinkAccount(int userId, String provider) async {
    await _oauthRepo.deleteByUserAndProvider(userId, provider);
  }

  /// Liste verknüpfter OAuth-Accounts eines Users
  Future<List<OAuthAccount>> getLinkedAccounts(int userId) async {
    return await _oauthRepo.findByUserId(userId);
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
import '../services/oauth_service.dart';
import '../models/oauth_models.dart';

class OAuthHandler {
  final OAuthService _oauthService;

  // State-Store mit Timestamp für Timeout
  final Map<String, DateTime> _stateStore = {};
  final Duration _stateTimeout = const Duration(minutes: 10);

  OAuthHandler(this._oauthService);

  Router get router {
    final router = Router();

    // Verfügbare Provider auflisten
    router.get('/providers', _listProviders);

    // OAuth-Flow initiieren
    router.get('/<provider>', _initiateOAuth);

    // Callback verarbeiten
    router.get('/<provider>/callback', _handleCallback);

    return router;
  }

  Future<Response> _listProviders(Request request) async {
    return Response.ok(
      jsonEncode({
        'providers': _oauthService.availableProviders,
      }),
      headers: {'content-type': 'application/json'},
    );
  }

  Future<Response> _initiateOAuth(Request request) async {
    try {
      final provider = request.params['provider']!;

      // State generieren
      final state = _oauthService.generateState();
      _stateStore[state] = DateTime.now();

      // Alte States aufräumen
      _cleanupExpiredStates();

      // Authorization URL generieren
      final authUrl = _oauthService.getAuthorizationUrl(provider, state);

      // Redirect zum Provider
      return Response.found(authUrl);
    } on OAuthException catch (e) {
      return _errorResponse(400, e.message);
    }
  }

  Future<Response> _handleCallback(Request request) async {
    final provider = request.params['provider']!;
    final queryParams = request.url.queryParameters;

    final code = queryParams['code'];
    final state = queryParams['state'];
    final error = queryParams['error'];
    final errorDescription = queryParams['error_description'];

    // 1. Error vom Provider
    if (error != null) {
      return _errorResponse(400, errorDescription ?? error);
    }

    // 2. Code fehlt
    if (code == null) {
      return _errorResponse(400, 'No authorization code received');
    }

    // 3. State validieren
    if (state == null || !_validateAndRemoveState(state)) {
      return _errorResponse(400, 'Invalid or expired state parameter');
    }

    try {
      // 4. OAuth-Flow abschließen
      final tokens = await _oauthService.handleCallback(
        provider: provider,
        code: code,
      );

      // 5. Erfolg-Response
      return Response.ok(
        jsonEncode({
          'message': 'Login successful',
          ...tokens.toJson(),
        }),
        headers: {'content-type': 'application/json'},
      );
    } on OAuthException catch (e) {
      return _errorResponse(e.statusCode ?? 400, e.message);
    } catch (e) {
      return _errorResponse(500, 'OAuth authentication failed');
    }
  }

  bool _validateAndRemoveState(String state) {
    final timestamp = _stateStore.remove(state);
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) < _stateTimeout;
  }

  void _cleanupExpiredStates() {
    final now = DateTime.now();
    _stateStore.removeWhere((_, timestamp) =>
        now.difference(timestamp) > _stateTimeout);
  }

  Response _errorResponse(int statusCode, String message) {
    return Response(
      statusCode,
      body: jsonEncode({'error': message}),
      headers: {'content-type': 'application/json'},
    );
  }
}
```

---

## Integration

```dart
// bin/server.dart (Erweiterung)

void main() async {
  // ... bestehende Initialisierung ...

  // OAuth Config
  final oauthConfig = OAuthConfig.fromEnvironment();

  // OAuth Service
  final oauthService = OAuthService(
    userRepo: userRepo,
    oauthRepo: oauthAccountRepo,
    jwtService: jwtService,
  );

  // Provider registrieren
  if (oauthConfig.googleClientId.isNotEmpty) {
    oauthService.registerProvider(GoogleOAuthProvider(
      clientId: oauthConfig.googleClientId,
      clientSecret: oauthConfig.googleClientSecret,
      redirectUri: oauthConfig.googleRedirectUri,
    ));
  }

  if (oauthConfig.githubClientId.isNotEmpty) {
    oauthService.registerProvider(GitHubOAuthProvider(
      clientId: oauthConfig.githubClientId,
      clientSecret: oauthConfig.githubClientSecret,
      redirectUri: oauthConfig.githubRedirectUri,
    ));
  }

  // Handler
  final oauthHandler = OAuthHandler(oauthService);

  // Router
  final router = Router();
  router.mount('/api/auth/oauth', oauthHandler.router);
  // ... weitere Routen ...
}
```

