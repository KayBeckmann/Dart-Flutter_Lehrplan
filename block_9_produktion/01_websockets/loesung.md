# Lösung 9.1: WebSockets & Real-time

## Aufgabe 1: Echo-Server

```dart
// bin/echo_server.dart

import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() async {
  final handler = webSocketHandler((WebSocketChannel socket) {
    print('Client connected');

    // Willkommensnachricht
    socket.sink.add('Connected!');

    // Auf Nachrichten hören
    socket.stream.listen(
      (message) {
        print('Received: $message');
        socket.sink.add('Echo: $message');
      },
      onDone: () {
        print('Client disconnected');
      },
      onError: (error) {
        print('Error: $error');
      },
    );
  });

  final server = await io.serve(handler, 'localhost', 8080);
  print('Echo server running on ws://localhost:${server.port}');
}
```

---

## Aufgabe 2: Connection Manager

```dart
// lib/connection_manager.dart

import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class Client {
  final String id;
  final WebSocketChannel socket;
  final DateTime connectedAt;
  String? name;

  Client({
    required this.id,
    required this.socket,
    required this.connectedAt,
    this.name,
  });

  void send(Map<String, dynamic> message) {
    socket.sink.add(jsonEncode(message));
  }

  void sendRaw(String data) {
    socket.sink.add(data);
  }

  @override
  String toString() => 'Client(id: $id, name: $name)';
}

class ConnectionManager {
  final Map<String, Client> _clients = {};
  final _uuid = Uuid();

  /// Neue Verbindung registrieren
  Client addConnection(WebSocketChannel socket) {
    final id = _uuid.v4();
    final client = Client(
      id: id,
      socket: socket,
      connectedAt: DateTime.now(),
    );

    _clients[id] = client;
    print('Client connected: $id (total: ${_clients.length})');

    return client;
  }

  /// Verbindung entfernen
  void removeConnection(String clientId) {
    final client = _clients.remove(clientId);
    if (client != null) {
      print('Client disconnected: $clientId (total: ${_clients.length})');
    }
  }

  /// Client abrufen
  Client? getClient(String clientId) => _clients[clientId];

  /// Nachricht an alle senden
  void broadcast(Map<String, dynamic> message, {String? excludeId}) {
    final encoded = jsonEncode(message);
    for (final entry in _clients.entries) {
      if (entry.key != excludeId) {
        entry.value.sendRaw(encoded);
      }
    }
  }

  /// Nachricht an bestimmten Client senden
  void sendTo(String clientId, Map<String, dynamic> message) {
    _clients[clientId]?.send(message);
  }

  /// Anzahl verbundener Clients
  int get clientCount => _clients.length;

  /// Alle Client-IDs
  List<String> get clientIds => _clients.keys.toList();

  /// Alle Clients
  Iterable<Client> get clients => _clients.values;
}
```

---

## Aufgabe 3: Notification Service

```dart
// lib/notification_service.dart

import 'connection_manager.dart';

class NotificationChannel {
  final String name;
  final Set<String> subscribers = {};
  final DateTime createdAt;

  NotificationChannel(this.name) : createdAt = DateTime.now();

  void subscribe(String clientId) {
    subscribers.add(clientId);
  }

  void unsubscribe(String clientId) {
    subscribers.remove(clientId);
  }

  bool hasSubscriber(String clientId) {
    return subscribers.contains(clientId);
  }

  int get subscriberCount => subscribers.length;

  bool get isEmpty => subscribers.isEmpty;
}

class NotificationService {
  final ConnectionManager _connections;
  final Map<String, NotificationChannel> _channels = {};

  NotificationService(this._connections);

  /// Client für Channel anmelden
  void subscribe(String clientId, String channelName) {
    // Channel erstellen falls nicht vorhanden
    final channel = _channels.putIfAbsent(
      channelName,
      () => NotificationChannel(channelName),
    );

    // Client zum Channel hinzufügen
    channel.subscribe(clientId);

    // Bestätigung an Client senden
    _connections.sendTo(clientId, {
      'type': 'subscribed',
      'channel': channelName,
      'subscriberCount': channel.subscriberCount,
    });

    print('Client $clientId subscribed to $channelName');
  }

  /// Client von Channel abmelden
  void unsubscribe(String clientId, String channelName) {
    final channel = _channels[channelName];
    if (channel == null) return;

    channel.unsubscribe(clientId);

    // Bestätigung senden
    _connections.sendTo(clientId, {
      'type': 'unsubscribed',
      'channel': channelName,
    });

    // Leere Channels aufräumen
    if (channel.isEmpty) {
      _channels.remove(channelName);
    }

    print('Client $clientId unsubscribed from $channelName');
  }

  /// Notification an Channel senden
  int notify(String channelName, Map<String, dynamic> data) {
    final channel = _channels[channelName];
    if (channel == null) return 0;

    final message = {
      'type': 'notification',
      'channel': channelName,
      'timestamp': DateTime.now().toIso8601String(),
      ...data,
    };

    int delivered = 0;
    for (final clientId in channel.subscribers) {
      final client = _connections.getClient(clientId);
      if (client != null) {
        client.send(message);
        delivered++;
      }
    }

    print('Notification sent to $delivered clients on $channelName');
    return delivered;
  }

  /// Client komplett entfernen (bei Disconnect)
  void removeClient(String clientId) {
    final emptyChannels = <String>[];

    for (final entry in _channels.entries) {
      entry.value.unsubscribe(clientId);
      if (entry.value.isEmpty) {
        emptyChannels.add(entry.key);
      }
    }

    // Leere Channels entfernen
    for (final name in emptyChannels) {
      _channels.remove(name);
    }
  }

  /// Channels eines Clients
  List<String> getSubscriptions(String clientId) {
    return _channels.entries
        .where((e) => e.value.hasSubscriber(clientId))
        .map((e) => e.key)
        .toList();
  }

  /// Alle Channels
  Map<String, int> getChannelStats() {
    return Map.fromEntries(
      _channels.entries.map((e) => MapEntry(e.key, e.value.subscriberCount)),
    );
  }

  /// Anzahl Channels
  int get channelCount => _channels.length;
}
```

---

## Aufgabe 4: Message Protocol

```dart
// lib/messages.dart

import 'dart:convert';

/// Basis für alle Messages
abstract class WsMessage {
  String get type;
  Map<String, dynamic> toJson();

  String encode() => jsonEncode(toJson());
}

/// Client → Server: Subscribe
class SubscribeMessage extends WsMessage {
  final String channel;

  SubscribeMessage(this.channel);

  @override
  String get type => 'subscribe';

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'channel': channel,
      };

  factory SubscribeMessage.fromJson(Map<String, dynamic> json) {
    return SubscribeMessage(json['channel'] as String);
  }
}

/// Client → Server: Unsubscribe
class UnsubscribeMessage extends WsMessage {
  final String channel;

  UnsubscribeMessage(this.channel);

  @override
  String get type => 'unsubscribe';

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'channel': channel,
      };

  factory UnsubscribeMessage.fromJson(Map<String, dynamic> json) {
    return UnsubscribeMessage(json['channel'] as String);
  }
}

/// Client → Server: Set Name
class SetNameMessage extends WsMessage {
  final String name;

  SetNameMessage(this.name);

  @override
  String get type => 'set_name';

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'name': name,
      };

  factory SetNameMessage.fromJson(Map<String, dynamic> json) {
    return SetNameMessage(json['name'] as String);
  }
}

/// Server → Client: Notification
class NotificationMessage extends WsMessage {
  final String channel;
  final String title;
  final String body;
  final DateTime timestamp;
  final Map<String, dynamic>? data;

  NotificationMessage({
    required this.channel,
    required this.title,
    required this.body,
    DateTime? timestamp,
    this.data,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String get type => 'notification';

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'channel': channel,
        'title': title,
        'body': body,
        'timestamp': timestamp.toIso8601String(),
        if (data != null) 'data': data,
      };

  factory NotificationMessage.fromJson(Map<String, dynamic> json) {
    return NotificationMessage(
      channel: json['channel'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      data: json['data'] as Map<String, dynamic>?,
    );
  }
}

/// Server → Client: Error
class ErrorMessage extends WsMessage {
  final String error;
  final String? code;

  ErrorMessage(this.error, {this.code});

  @override
  String get type => 'error';

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'error': error,
        if (code != null) 'code': code,
      };

  factory ErrorMessage.fromJson(Map<String, dynamic> json) {
    return ErrorMessage(
      json['error'] as String,
      code: json['code'] as String?,
    );
  }
}

/// Server → Client: Subscription confirmed
class SubscribedMessage extends WsMessage {
  final String channel;
  final int subscriberCount;

  SubscribedMessage(this.channel, {this.subscriberCount = 0});

  @override
  String get type => 'subscribed';

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'channel': channel,
        'subscriberCount': subscriberCount,
      };

  factory SubscribedMessage.fromJson(Map<String, dynamic> json) {
    return SubscribedMessage(
      json['channel'] as String,
      subscriberCount: json['subscriberCount'] as int? ?? 0,
    );
  }
}

/// Server → Client: Welcome
class WelcomeMessage extends WsMessage {
  final String clientId;

  WelcomeMessage(this.clientId);

  @override
  String get type => 'welcome';

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'clientId': clientId,
      };
}

/// Message Parser
WsMessage? parseMessage(String data) {
  try {
    final json = jsonDecode(data) as Map<String, dynamic>;
    final type = json['type'] as String?;

    switch (type) {
      case 'subscribe':
        return SubscribeMessage.fromJson(json);
      case 'unsubscribe':
        return UnsubscribeMessage.fromJson(json);
      case 'set_name':
        return SetNameMessage.fromJson(json);
      case 'notification':
        return NotificationMessage.fromJson(json);
      case 'error':
        return ErrorMessage.fromJson(json);
      case 'subscribed':
        return SubscribedMessage.fromJson(json);
      default:
        return null;
    }
  } catch (e) {
    return null;
  }
}
```

---

## Aufgabe 5: WebSocket Handler

```dart
// lib/ws_handler.dart

import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'connection_manager.dart';
import 'notification_service.dart';
import 'messages.dart';

class NotificationHandler {
  final ConnectionManager connections;
  final NotificationService notifications;

  NotificationHandler(this.connections, this.notifications);

  void handleConnection(WebSocketChannel socket) {
    // Client registrieren
    final client = connections.addConnection(socket);

    // Willkommensnachricht senden
    client.send({
      'type': 'welcome',
      'clientId': client.id,
      'message': 'Connected to notification server',
    });

    // Auf Nachrichten hören
    socket.stream.listen(
      (data) {
        _handleMessage(client, data as String);
      },
      onDone: () {
        _handleDisconnect(client);
      },
      onError: (error) {
        print('WebSocket error for ${client.id}: $error');
        _handleDisconnect(client);
      },
    );
  }

  void _handleMessage(Client client, String data) {
    try {
      final json = jsonDecode(data) as Map<String, dynamic>;
      final type = json['type'] as String?;

      switch (type) {
        case 'subscribe':
          final channel = json['channel'] as String?;
          if (channel != null && channel.isNotEmpty) {
            notifications.subscribe(client.id, channel);
          } else {
            _sendError(client, 'Channel name required');
          }
          break;

        case 'unsubscribe':
          final channel = json['channel'] as String?;
          if (channel != null) {
            notifications.unsubscribe(client.id, channel);
          }
          break;

        case 'set_name':
          final name = json['name'] as String?;
          if (name != null && name.isNotEmpty) {
            client.name = name;
            client.send({
              'type': 'name_set',
              'name': name,
            });
          } else {
            _sendError(client, 'Name required');
          }
          break;

        case 'list_subscriptions':
          final subs = notifications.getSubscriptions(client.id);
          client.send({
            'type': 'subscriptions',
            'channels': subs,
          });
          break;

        case 'ping':
          client.send({
            'type': 'pong',
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          });
          break;

        default:
          _sendError(client, 'Unknown message type: $type');
      }
    } catch (e) {
      _sendError(client, 'Invalid message format: $e');
    }
  }

  void _handleDisconnect(Client client) {
    notifications.removeClient(client.id);
    connections.removeConnection(client.id);
  }

  void _sendError(Client client, String message) {
    client.send({
      'type': 'error',
      'error': message,
    });
  }
}
```

---

## Aufgabe 6: REST API

```dart
// lib/api_handler.dart

import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'connection_manager.dart';
import 'notification_service.dart';

class NotificationApiHandler {
  final ConnectionManager connections;
  final NotificationService notifications;

  NotificationApiHandler(this.connections, this.notifications);

  Router get router {
    final router = Router();

    router.post('/notify/<channel>', _sendNotification);
    router.get('/channels', _listChannels);
    router.get('/stats', _getStats);
    router.get('/clients', _listClients);

    return router;
  }

  Future<Response> _sendNotification(Request request, String channel) async {
    try {
      final body = await request.readAsString();
      final json = jsonDecode(body) as Map<String, dynamic>;

      final title = json['title'] as String? ?? 'Notification';
      final messageBody = json['body'] as String? ?? '';
      final data = json['data'] as Map<String, dynamic>?;

      final delivered = notifications.notify(channel, {
        'title': title,
        'body': messageBody,
        if (data != null) 'data': data,
      });

      return Response.ok(
        jsonEncode({
          'success': true,
          'channel': channel,
          'delivered': delivered,
        }),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.badRequest(
        body: jsonEncode({
          'error': 'Invalid request body',
          'details': e.toString(),
        }),
        headers: {'content-type': 'application/json'},
      );
    }
  }

  Future<Response> _listChannels(Request request) async {
    final stats = notifications.getChannelStats();

    return Response.ok(
      jsonEncode({
        'channels': stats.entries
            .map((e) => {
                  'name': e.key,
                  'subscribers': e.value,
                })
            .toList(),
        'total': stats.length,
      }),
      headers: {'content-type': 'application/json'},
    );
  }

  Future<Response> _getStats(Request request) async {
    return Response.ok(
      jsonEncode({
        'connections': connections.clientCount,
        'channels': notifications.channelCount,
        'timestamp': DateTime.now().toIso8601String(),
      }),
      headers: {'content-type': 'application/json'},
    );
  }

  Future<Response> _listClients(Request request) async {
    final clients = connections.clients.map((c) => {
          'id': c.id,
          'name': c.name,
          'connectedAt': c.connectedAt.toIso8601String(),
          'subscriptions': notifications.getSubscriptions(c.id),
        });

    return Response.ok(
      jsonEncode({
        'clients': clients.toList(),
        'total': connections.clientCount,
      }),
      headers: {'content-type': 'application/json'},
    );
  }
}
```

---

## Aufgabe 7: Server Assembly

```dart
// bin/server.dart

import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';

import '../lib/connection_manager.dart';
import '../lib/notification_service.dart';
import '../lib/ws_handler.dart';
import '../lib/api_handler.dart';

void main() async {
  // Services erstellen
  final connections = ConnectionManager();
  final notifications = NotificationService(connections);
  final wsHandler = NotificationHandler(connections, notifications);
  final apiHandler = NotificationApiHandler(connections, notifications);

  // Router mit WebSocket und REST
  final router = Router();

  // WebSocket auf /ws
  router.get('/ws', webSocketHandler(wsHandler.handleConnection));

  // REST API
  router.mount('/api/', apiHandler.router.call);

  // Health Check
  router.get('/health', (Request request) {
    return Response.ok('OK');
  });

  // Pipeline mit CORS und Logging
  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(_corsMiddleware())
      .addHandler(router.call);

  // Server starten
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await io.serve(handler, InternetAddress.anyIPv4, port);

  print('===========================================');
  print('Notification Server running on port ${server.port}');
  print('===========================================');
  print('WebSocket:  ws://localhost:${server.port}/ws');
  print('REST API:   http://localhost:${server.port}/api');
  print('');
  print('Endpoints:');
  print('  POST /api/notify/:channel  - Send notification');
  print('  GET  /api/channels         - List channels');
  print('  GET  /api/stats            - Server statistics');
  print('  GET  /api/clients          - List clients');
  print('  GET  /health               - Health check');
  print('===========================================');

  // Graceful Shutdown
  ProcessSignal.sigint.watch().listen((_) async {
    print('\nShutting down...');

    // Alle Clients benachrichtigen
    connections.broadcast({
      'type': 'server_shutdown',
      'message': 'Server is shutting down',
    });

    await Future.delayed(Duration(milliseconds: 500));
    await server.close();
    exit(0);
  });
}

Middleware _corsMiddleware() {
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
  };

  return (Handler innerHandler) {
    return (Request request) async {
      if (request.method == 'OPTIONS') {
        return Response.ok('', headers: corsHeaders);
      }

      final response = await innerHandler(request);
      return response.change(headers: corsHeaders);
    };
  };
}
```

---

## Aufgabe 8: Client Simulator

```dart
// bin/client.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() async {
  final url = Platform.environment['WS_URL'] ?? 'ws://localhost:8080/ws';

  print('Connecting to $url...');

  final channel = WebSocketChannel.connect(Uri.parse(url));

  // Auf Server-Nachrichten hören
  channel.stream.listen(
    (data) {
      final message = jsonDecode(data as String);
      _printMessage(message);
    },
    onDone: () {
      print('Connection closed');
      exit(0);
    },
    onError: (error) {
      print('Error: $error');
      exit(1);
    },
  );

  print('Connected! Commands:');
  print('  sub <channel>   - Subscribe to channel');
  print('  unsub <channel> - Unsubscribe from channel');
  print('  name <name>     - Set your name');
  print('  list            - List subscriptions');
  print('  ping            - Send ping');
  print('  quit            - Exit');
  print('');

  // Stdin lesen
  await for (final line in stdin.transform(utf8.decoder).transform(LineSplitter())) {
    final parts = line.trim().split(' ');
    if (parts.isEmpty) continue;

    final cmd = parts[0].toLowerCase();
    final arg = parts.length > 1 ? parts.sublist(1).join(' ') : null;

    switch (cmd) {
      case 'sub':
        if (arg != null && arg.isNotEmpty) {
          _send(channel, {'type': 'subscribe', 'channel': arg});
          print('→ Subscribing to "$arg"...');
        } else {
          print('Usage: sub <channel>');
        }
        break;

      case 'unsub':
        if (arg != null && arg.isNotEmpty) {
          _send(channel, {'type': 'unsubscribe', 'channel': arg});
          print('→ Unsubscribing from "$arg"...');
        } else {
          print('Usage: unsub <channel>');
        }
        break;

      case 'name':
        if (arg != null && arg.isNotEmpty) {
          _send(channel, {'type': 'set_name', 'name': arg});
          print('→ Setting name to "$arg"...');
        } else {
          print('Usage: name <your-name>');
        }
        break;

      case 'list':
        _send(channel, {'type': 'list_subscriptions'});
        print('→ Requesting subscriptions...');
        break;

      case 'ping':
        _send(channel, {'type': 'ping'});
        print('→ Ping sent');
        break;

      case 'quit':
      case 'exit':
        print('Goodbye!');
        channel.sink.close();
        exit(0);

      case 'help':
        print('Commands: sub, unsub, name, list, ping, quit');
        break;

      default:
        print('Unknown command: $cmd (type "help" for commands)');
    }
  }
}

void _send(WebSocketChannel channel, Map<String, dynamic> message) {
  channel.sink.add(jsonEncode(message));
}

void _printMessage(Map<String, dynamic> message) {
  final type = message['type'] as String?;

  switch (type) {
    case 'welcome':
      print('✓ Connected as ${message['clientId']}');
      break;

    case 'subscribed':
      print('✓ Subscribed to "${message['channel']}" (${message['subscriberCount']} subscribers)');
      break;

    case 'unsubscribed':
      print('✓ Unsubscribed from "${message['channel']}"');
      break;

    case 'name_set':
      print('✓ Name set to "${message['name']}"');
      break;

    case 'notification':
      print('');
      print('╔══════════════════════════════════════════');
      print('║ 🔔 NOTIFICATION [${message['channel']}]');
      print('║ Title: ${message['title']}');
      print('║ Body: ${message['body']}');
      if (message['data'] != null) {
        print('║ Data: ${message['data']}');
      }
      print('╚══════════════════════════════════════════');
      print('');
      break;

    case 'subscriptions':
      final channels = message['channels'] as List;
      print('✓ Your subscriptions: ${channels.isEmpty ? '(none)' : channels.join(', ')}');
      break;

    case 'pong':
      print('✓ Pong received');
      break;

    case 'error':
      print('✗ Error: ${message['error']}');
      break;

    case 'server_shutdown':
      print('⚠ Server is shutting down: ${message['message']}');
      break;

    default:
      print('← $message');
  }
}
```

---

## Bonus: Heartbeat

```dart
// lib/heartbeat.dart

import 'dart:async';
import 'connection_manager.dart';

class HeartbeatManager {
  final Duration pingInterval;
  final Duration timeout;
  final ConnectionManager connections;
  final void Function(String clientId)? onTimeout;

  final Map<String, DateTime> _lastPong = {};
  Timer? _timer;

  HeartbeatManager({
    required this.connections,
    this.pingInterval = const Duration(seconds: 30),
    this.timeout = const Duration(seconds: 60),
    this.onTimeout,
  });

  void start() {
    _timer = Timer.periodic(pingInterval, (_) {
      _checkConnections();
    });
    print('Heartbeat started (interval: ${pingInterval.inSeconds}s, timeout: ${timeout.inSeconds}s)');
  }

  void _checkConnections() {
    final now = DateTime.now();
    final timedOut = <String>[];

    for (final client in connections.clients) {
      final lastPong = _lastPong[client.id];

      // Neuer Client ohne Pong
      if (lastPong == null) {
        _lastPong[client.id] = client.connectedAt;
      }
      // Timeout prüfen
      else if (now.difference(lastPong) > timeout) {
        timedOut.add(client.id);
        continue;
      }

      // Ping senden
      client.send({
        'type': 'ping',
        'timestamp': now.millisecondsSinceEpoch,
      });
    }

    // Timeouts verarbeiten
    for (final clientId in timedOut) {
      print('Client $clientId timed out');
      _lastPong.remove(clientId);

      final client = connections.getClient(clientId);
      if (client != null) {
        client.socket.sink.close(1000, 'Ping timeout');
      }

      onTimeout?.call(clientId);
    }
  }

  void handlePong(String clientId) {
    _lastPong[clientId] = DateTime.now();
  }

  void removeClient(String clientId) {
    _lastPong.remove(clientId);
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _lastPong.clear();
    print('Heartbeat stopped');
  }
}
```

### Integration in Handler

```dart
// In ws_handler.dart erweitern

class NotificationHandler {
  final ConnectionManager connections;
  final NotificationService notifications;
  final HeartbeatManager heartbeat;

  NotificationHandler(this.connections, this.notifications)
      : heartbeat = HeartbeatManager(
          connections: connections,
          onTimeout: (clientId) {
            notifications.removeClient(clientId);
            connections.removeConnection(clientId);
          },
        ) {
    heartbeat.start();
  }

  void _handleMessage(Client client, String data) {
    // ... existing code ...

    switch (type) {
      case 'pong':
        heartbeat.handlePong(client.id);
        break;

      // ... other cases ...
    }
  }

  void _handleDisconnect(Client client) {
    heartbeat.removeClient(client.id);
    notifications.removeClient(client.id);
    connections.removeConnection(client.id);
  }
}
```

---

## Projektstruktur

```
notification_server/
├── bin/
│   ├── server.dart          # Hauptserver
│   └── client.dart          # Test-Client
├── lib/
│   ├── connection_manager.dart
│   ├── notification_service.dart
│   ├── messages.dart
│   ├── ws_handler.dart
│   ├── api_handler.dart
│   └── heartbeat.dart
├── pubspec.yaml
└── README.md
```

---

## Test-Szenario

```bash
# Terminal 1: Server starten
dart run bin/server.dart

# Terminal 2: Client 1
dart run bin/client.dart
> name Alice
> sub news
> sub sports

# Terminal 3: Client 2
dart run bin/client.dart
> name Bob
> sub news

# Terminal 4: Notification senden
curl -X POST http://localhost:8080/api/notify/news \
  -H "Content-Type: application/json" \
  -d '{"title": "Breaking", "body": "Big news!"}'

# Stats abrufen
curl http://localhost:8080/api/stats
curl http://localhost:8080/api/channels
curl http://localhost:8080/api/clients
```
