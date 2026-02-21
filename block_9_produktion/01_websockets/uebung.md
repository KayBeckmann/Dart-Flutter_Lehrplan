# Übung 9.1: WebSockets & Real-time

## Ziel

Entwickle einen Real-time Notification Service mit WebSockets.

---

## Vorbereitung

### Dependencies

```yaml
# pubspec.yaml
dependencies:
  shelf: ^1.4.0
  shelf_router: ^1.1.0
  shelf_web_socket: ^2.0.0
  web_socket_channel: ^3.0.0
  uuid: ^4.0.0
```

---

## Aufgabe 1: Einfacher Echo-Server (15 min)

Erstelle einen WebSocket-Server, der empfangene Nachrichten zurücksendet.

```dart
// bin/echo_server.dart

import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() async {
  // TODO: WebSocket Handler erstellen
  // - Bei Verbindung "Connected!" senden
  // - Empfangene Nachrichten mit "Echo: " Prefix zurücksenden
  // - Bei Disconnect loggen

  // TODO: Server auf Port 8080 starten
}
```

**Test mit websocat:**
```bash
# Installation: cargo install websocat
websocat ws://localhost:8080
> Hello
< Connected!
< Echo: Hello
```

---

## Aufgabe 2: Connection Manager (20 min)

Implementiere einen Connection Manager für mehrere Clients.

```dart
// lib/connection_manager.dart

import 'package:web_socket_channel/web_socket_channel.dart';

class Client {
  final String id;
  final WebSocketChannel socket;
  final DateTime connectedAt;
  String? name;

  // TODO: Implementieren
}

class ConnectionManager {
  final Map<String, Client> _clients = {};

  /// Neue Verbindung registrieren
  Client addConnection(WebSocketChannel socket) {
    // TODO: Client erstellen und speichern
  }

  /// Verbindung entfernen
  void removeConnection(String clientId) {
    // TODO
  }

  /// Nachricht an alle senden
  void broadcast(Map<String, dynamic> message, {String? excludeId}) {
    // TODO: An alle außer excludeId senden
  }

  /// Nachricht an bestimmten Client senden
  void sendTo(String clientId, Map<String, dynamic> message) {
    // TODO
  }

  /// Anzahl verbundener Clients
  int get clientCount => _clients.length;

  /// Alle Client-IDs
  List<String> get clientIds => _clients.keys.toList();
}
```

---

## Aufgabe 3: Notification Service (25 min)

Baue einen Notification Service mit Channels.

```dart
// lib/notification_service.dart

class NotificationChannel {
  final String name;
  final Set<String> subscribers = {};

  NotificationChannel(this.name);

  void subscribe(String clientId) {
    // TODO
  }

  void unsubscribe(String clientId) {
    // TODO
  }

  bool hasSubscriber(String clientId) {
    // TODO
  }
}

class NotificationService {
  final ConnectionManager _connections;
  final Map<String, NotificationChannel> _channels = {};

  NotificationService(this._connections);

  /// Client für Channel anmelden
  void subscribe(String clientId, String channelName) {
    // TODO: Channel erstellen falls nicht vorhanden
    // TODO: Client zum Channel hinzufügen
    // TODO: Bestätigung an Client senden
  }

  /// Client von Channel abmelden
  void unsubscribe(String clientId, String channelName) {
    // TODO
  }

  /// Notification an Channel senden
  void notify(String channelName, Map<String, dynamic> data) {
    // TODO: Nachricht an alle Subscriber des Channels senden
  }

  /// Client komplett entfernen (bei Disconnect)
  void removeClient(String clientId) {
    // TODO: Aus allen Channels entfernen
  }

  /// Channels eines Clients
  List<String> getSubscriptions(String clientId) {
    // TODO
  }
}
```

---

## Aufgabe 4: Message Protocol (20 min)

Definiere ein strukturiertes Message-Protokoll.

```dart
// lib/messages.dart

/// Basis für alle Messages
abstract class WsMessage {
  String get type;
  Map<String, dynamic> toJson();
}

/// Client → Server: Subscribe
class SubscribeMessage extends WsMessage {
  final String channel;

  SubscribeMessage(this.channel);

  @override
  String get type => 'subscribe';

  @override
  Map<String, dynamic> toJson() {
    // TODO
  }

  factory SubscribeMessage.fromJson(Map<String, dynamic> json) {
    // TODO
  }
}

/// Client → Server: Unsubscribe
class UnsubscribeMessage extends WsMessage {
  // TODO: Analog zu SubscribeMessage
}

/// Server → Client: Notification
class NotificationMessage extends WsMessage {
  final String channel;
  final String title;
  final String body;
  final DateTime timestamp;
  final Map<String, dynamic>? data;

  // TODO: Implementieren
}

/// Server → Client: Error
class ErrorMessage extends WsMessage {
  final String error;
  final String? code;

  // TODO: Implementieren
}

/// Server → Client: Subscription confirmed
class SubscribedMessage extends WsMessage {
  final String channel;

  // TODO: Implementieren
}

/// Message Parser
WsMessage? parseMessage(String data) {
  // TODO: JSON parsen und richtige Message-Klasse zurückgeben
}
```

---

## Aufgabe 5: WebSocket Handler (25 min)

Verbinde alles in einem Handler.

```dart
// lib/ws_handler.dart

import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class NotificationHandler {
  final ConnectionManager connections;
  final NotificationService notifications;

  NotificationHandler(this.connections, this.notifications);

  void handleConnection(WebSocketChannel socket) {
    // TODO: Client registrieren
    final client = connections.addConnection(socket);

    // TODO: Willkommensnachricht senden

    // TODO: Auf Nachrichten hören
    socket.stream.listen(
      (data) {
        _handleMessage(client, data as String);
      },
      onDone: () {
        // TODO: Aufräumen bei Disconnect
      },
      onError: (error) {
        // TODO: Error handling
      },
    );
  }

  void _handleMessage(Client client, String data) {
    try {
      final message = parseMessage(data);

      // TODO: Switch über message.type
      // - 'subscribe': Channel abonnieren
      // - 'unsubscribe': Channel verlassen
      // - 'set_name': Client-Namen setzen

    } catch (e) {
      // TODO: Error zurücksenden
    }
  }
}
```

---

## Aufgabe 6: REST API für Notifications (20 min)

Erstelle REST-Endpoints zum Senden von Notifications.

```dart
// lib/api_handler.dart

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

class NotificationApiHandler {
  final NotificationService notifications;

  NotificationApiHandler(this.notifications);

  Router get router {
    final router = Router();

    // POST /api/notify/:channel
    // Body: {"title": "...", "body": "...", "data": {...}}
    router.post('/api/notify/<channel>', _sendNotification);

    // GET /api/channels
    // Returns: {"channels": ["channel1", "channel2"], "subscribers": {...}}
    router.get('/api/channels', _listChannels);

    // GET /api/stats
    // Returns: {"connections": 5, "channels": 3}
    router.get('/api/stats', _getStats);

    return router;
  }

  Future<Response> _sendNotification(Request request, String channel) async {
    // TODO: Body parsen
    // TODO: Notification senden
    // TODO: Response mit Anzahl erreichter Clients
  }

  Future<Response> _listChannels(Request request) async {
    // TODO
  }

  Future<Response> _getStats(Request request) async {
    // TODO
  }
}
```

---

## Aufgabe 7: Server Assembly (15 min)

Führe alles zusammen.

```dart
// bin/server.dart

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';

void main() async {
  // TODO: Services erstellen
  final connections = ConnectionManager();
  final notifications = NotificationService(connections);
  final wsHandler = NotificationHandler(connections, notifications);
  final apiHandler = NotificationApiHandler(notifications);

  // TODO: Router mit WebSocket und REST
  final router = Router();

  // WebSocket auf /ws
  router.get('/ws', webSocketHandler(wsHandler.handleConnection));

  // REST API
  router.mount('/api', apiHandler.router.call);

  // TODO: Pipeline mit CORS und Logging

  // TODO: Server starten

  print('Notification Server running on http://localhost:8080');
  print('WebSocket: ws://localhost:8080/ws');
  print('Send notification: POST http://localhost:8080/api/notify/:channel');
}
```

---

## Aufgabe 8: Client Simulator (15 min)

Schreibe einen Test-Client.

```dart
// bin/client.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() async {
  final channel = WebSocketChannel.connect(Uri.parse('ws://localhost:8080/ws'));

  // TODO: Auf Server-Nachrichten hören und ausgeben
  channel.stream.listen((data) {
    final message = jsonDecode(data as String);
    print('Received: $message');
  });

  // TODO: Stdin lesen und Kommandos senden
  // Kommandos:
  // - sub <channel>: Channel abonnieren
  // - unsub <channel>: Channel verlassen
  // - name <name>: Namen setzen
  // - quit: Beenden

  print('Commands: sub <channel>, unsub <channel>, name <name>, quit');

  await for (final line in stdin.transform(utf8.decoder).transform(LineSplitter())) {
    final parts = line.split(' ');
    final cmd = parts[0];

    switch (cmd) {
      case 'sub':
        // TODO: Subscribe Message senden
        break;
      case 'unsub':
        // TODO: Unsubscribe Message senden
        break;
      case 'name':
        // TODO: Name setzen
        break;
      case 'quit':
        channel.sink.close();
        exit(0);
    }
  }
}
```

---

## Bonus: Heartbeat (Optional, 15 min)

Implementiere Heartbeat für Connection-Health.

```dart
// lib/heartbeat.dart

class HeartbeatManager {
  final Duration pingInterval;
  final Duration timeout;
  final ConnectionManager connections;
  final Map<String, DateTime> _lastPong = {};
  Timer? _timer;

  HeartbeatManager({
    required this.connections,
    this.pingInterval = const Duration(seconds: 30),
    this.timeout = const Duration(seconds: 60),
  });

  void start() {
    // TODO: Timer starten
    // TODO: Regelmäßig Pings senden
    // TODO: Timeouts prüfen
  }

  void handlePong(String clientId) {
    // TODO: Last pong Zeit aktualisieren
  }

  void stop() {
    // TODO: Timer stoppen
  }
}
```

---

## Testen

### 1. Server starten

```bash
dart run bin/server.dart
```

### 2. Client starten (mehrere Terminals)

```bash
dart run bin/client.dart
# > sub news
# > name Alice
```

### 3. Notification senden

```bash
curl -X POST http://localhost:8080/api/notify/news \
  -H "Content-Type: application/json" \
  -d '{"title": "Breaking News", "body": "Something happened!"}'
```

### 4. Stats prüfen

```bash
curl http://localhost:8080/api/stats
```

---

## Abgabe-Checkliste

- [ ] Echo-Server funktioniert
- [ ] ConnectionManager verwaltet Clients
- [ ] NotificationService mit Channels
- [ ] Strukturiertes Message-Protokoll
- [ ] WebSocket Handler verarbeitet Messages
- [ ] REST API zum Senden von Notifications
- [ ] Server mit WebSocket und REST kombiniert
- [ ] Client Simulator funktioniert
- [ ] Bonus: Heartbeat implementiert
