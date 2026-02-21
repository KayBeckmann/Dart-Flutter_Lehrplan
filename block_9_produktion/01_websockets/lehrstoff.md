# Einheit 9.1: WebSockets & Real-time

## Lernziele

- WebSocket-Protokoll verstehen
- Bidirektionale Kommunikation implementieren
- shelf_web_socket Package verwenden
- Real-time Features entwickeln

---

## WebSocket-Grundlagen

### Was sind WebSockets?

WebSockets ermöglichen bidirektionale, persistente Verbindungen zwischen Client und Server:

```
HTTP (Request-Response):
Client ──Request──> Server
Client <──Response── Server
(Verbindung geschlossen)

WebSocket (Bidirektional):
Client ══════════════ Server
       <──Messages──>
(Verbindung bleibt offen)
```

### Vorteile gegenüber HTTP

| Aspekt | HTTP Polling | WebSocket |
|--------|--------------|-----------|
| Latenz | Hoch (Request-Overhead) | Niedrig (persistente Verbindung) |
| Overhead | Groß (Header bei jedem Request) | Klein (nur bei Handshake) |
| Server → Client | Nur als Response | Jederzeit |
| Skalierung | Viele Connections | Weniger Connections |

### Wann WebSockets?

**Gute Anwendungsfälle:**
- Chat-Anwendungen
- Live-Notifications
- Collaborative Editing
- Real-time Dashboards
- Online Games
- Live Tracking

**Besser HTTP:**
- Standard CRUD
- Seltene Updates
- Request-Response Pattern

---

## WebSocket-Protokoll

### Handshake

WebSocket beginnt als HTTP-Upgrade:

```http
# Client Request
GET /ws HTTP/1.1
Host: server.example.com
Upgrade: websocket
Connection: Upgrade
Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==
Sec-WebSocket-Version: 13

# Server Response
HTTP/1.1 101 Switching Protocols
Upgrade: websocket
Connection: Upgrade
Sec-WebSocket-Accept: s3pPLMBiTxaQ9kYGzzhZRbK+xOo=
```

### Message Types

```dart
// Text Messages
socket.add('Hello, World!');

// Binary Messages
socket.add(Uint8List.fromList([0x01, 0x02, 0x03]));

// Close Frame
socket.close(1000, 'Normal closure');
```

### Close Codes

| Code | Bedeutung |
|------|-----------|
| 1000 | Normal Closure |
| 1001 | Going Away |
| 1002 | Protocol Error |
| 1003 | Unsupported Data |
| 1006 | Abnormal Closure |
| 1011 | Internal Error |

---

## shelf_web_socket Package

### Setup

```yaml
# pubspec.yaml
dependencies:
  shelf: ^1.4.0
  shelf_web_socket: ^2.0.0
  web_socket_channel: ^3.0.0
```

### Einfacher WebSocket Handler

```dart
import 'dart:async';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() async {
  final handler = webSocketHandler((WebSocketChannel webSocket) {
    // Verbindung hergestellt
    print('Client connected');

    // Willkommensnachricht senden
    webSocket.sink.add('Welcome!');

    // Auf Nachrichten hören
    webSocket.stream.listen(
      (message) {
        print('Received: $message');
        // Echo zurücksenden
        webSocket.sink.add('Echo: $message');
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
  print('WebSocket server running on ws://localhost:${server.port}');
}
```

### Integration mit Router

```dart
import 'package:shelf_router/shelf_router.dart';

Router createRouter() {
  final router = Router();

  // HTTP Endpoints
  router.get('/api/status', (Request request) {
    return Response.ok('{"status": "online"}');
  });

  // WebSocket Endpoint
  router.get('/ws', webSocketHandler((WebSocketChannel webSocket) {
    handleWebSocket(webSocket);
  }));

  return router;
}

void handleWebSocket(WebSocketChannel webSocket) {
  webSocket.stream.listen((message) {
    webSocket.sink.add('Received: $message');
  });
}
```

---

## Chat-Server Beispiel

### Architektur

```
┌─────────────────────────────────────────┐
│              ChatServer                  │
│  ┌─────────────────────────────────┐    │
│  │     Map<String, ChatRoom>       │    │
│  │  ┌─────────┐  ┌─────────┐       │    │
│  │  │ Room A  │  │ Room B  │       │    │
│  │  │ Users[] │  │ Users[] │       │    │
│  │  └─────────┘  └─────────┘       │    │
│  └─────────────────────────────────┘    │
└─────────────────────────────────────────┘
         ▲        ▲        ▲
         │        │        │
      Client1  Client2  Client3
```

### ChatUser Klasse

```dart
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class ChatUser {
  final String id;
  final String name;
  final WebSocketChannel socket;
  String? currentRoom;

  ChatUser({
    required this.id,
    required this.name,
    required this.socket,
  });

  void send(Map<String, dynamic> message) {
    socket.sink.add(jsonEncode(message));
  }

  void sendText(String type, String text) {
    send({'type': type, 'message': text});
  }

  void sendError(String error) {
    send({'type': 'error', 'message': error});
  }
}
```

### ChatRoom Klasse

```dart
class ChatRoom {
  final String name;
  final Set<ChatUser> users = {};
  final List<Map<String, dynamic>> messageHistory = [];
  final int maxHistorySize;

  ChatRoom(this.name, {this.maxHistorySize = 100});

  void join(ChatUser user) {
    users.add(user);
    user.currentRoom = name;

    // Benachrichtige andere User
    broadcast({
      'type': 'user_joined',
      'user': user.name,
      'room': name,
      'userCount': users.length,
    }, exclude: user);

    // Sende History an neuen User
    user.send({
      'type': 'room_joined',
      'room': name,
      'history': messageHistory.take(50).toList(),
      'users': users.map((u) => u.name).toList(),
    });
  }

  void leave(ChatUser user) {
    users.remove(user);
    user.currentRoom = null;

    broadcast({
      'type': 'user_left',
      'user': user.name,
      'room': name,
      'userCount': users.length,
    });
  }

  void broadcast(Map<String, dynamic> message, {ChatUser? exclude}) {
    final encoded = jsonEncode(message);
    for (final user in users) {
      if (user != exclude) {
        user.socket.sink.add(encoded);
      }
    }
  }

  void sendMessage(ChatUser sender, String text) {
    final message = {
      'type': 'message',
      'room': name,
      'user': sender.name,
      'text': text,
      'timestamp': DateTime.now().toIso8601String(),
    };

    // In History speichern
    messageHistory.add(message);
    if (messageHistory.length > maxHistorySize) {
      messageHistory.removeAt(0);
    }

    // An alle senden (inkl. Sender für Bestätigung)
    broadcast(message);
  }
}
```

### ChatServer

```dart
import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class ChatServer {
  final Map<String, ChatRoom> _rooms = {};
  final Map<String, ChatUser> _users = {};
  final _uuid = Uuid();

  ChatServer() {
    // Default-Räume erstellen
    _rooms['general'] = ChatRoom('general');
    _rooms['random'] = ChatRoom('random');
  }

  void handleConnection(WebSocketChannel socket) {
    final userId = _uuid.v4();
    ChatUser? user;

    socket.stream.listen(
      (data) {
        try {
          final message = jsonDecode(data as String) as Map<String, dynamic>;
          final type = message['type'] as String?;

          switch (type) {
            case 'auth':
              user = _handleAuth(userId, message, socket);
              break;
            case 'join':
              if (user != null) _handleJoin(user!, message);
              break;
            case 'leave':
              if (user != null) _handleLeave(user!);
              break;
            case 'message':
              if (user != null) _handleMessage(user!, message);
              break;
            case 'list_rooms':
              _handleListRooms(socket);
              break;
            default:
              socket.sink.add(jsonEncode({
                'type': 'error',
                'message': 'Unknown message type: $type',
              }));
          }
        } catch (e) {
          socket.sink.add(jsonEncode({
            'type': 'error',
            'message': 'Invalid message format',
          }));
        }
      },
      onDone: () {
        _handleDisconnect(user);
      },
      onError: (error) {
        print('WebSocket error: $error');
        _handleDisconnect(user);
      },
    );
  }

  ChatUser _handleAuth(String id, Map<String, dynamic> message, WebSocketChannel socket) {
    final name = message['name'] as String? ?? 'Anonymous';

    final user = ChatUser(
      id: id,
      name: name,
      socket: socket,
    );

    _users[id] = user;

    user.send({
      'type': 'auth_success',
      'userId': id,
      'name': name,
    });

    return user;
  }

  void _handleJoin(ChatUser user, Map<String, dynamic> message) {
    final roomName = message['room'] as String?;

    if (roomName == null) {
      user.sendError('Room name required');
      return;
    }

    // Aktuellen Raum verlassen
    if (user.currentRoom != null) {
      _rooms[user.currentRoom]?.leave(user);
    }

    // Raum erstellen falls nicht vorhanden
    _rooms.putIfAbsent(roomName, () => ChatRoom(roomName));

    // Beitreten
    _rooms[roomName]!.join(user);
  }

  void _handleLeave(ChatUser user) {
    if (user.currentRoom != null) {
      _rooms[user.currentRoom]?.leave(user);
    }
  }

  void _handleMessage(ChatUser user, Map<String, dynamic> message) {
    final text = message['text'] as String?;

    if (text == null || text.isEmpty) {
      user.sendError('Message text required');
      return;
    }

    if (user.currentRoom == null) {
      user.sendError('Join a room first');
      return;
    }

    _rooms[user.currentRoom]!.sendMessage(user, text);
  }

  void _handleListRooms(WebSocketChannel socket) {
    socket.sink.add(jsonEncode({
      'type': 'room_list',
      'rooms': _rooms.entries.map((e) => {
        'name': e.key,
        'userCount': e.value.users.length,
      }).toList(),
    }));
  }

  void _handleDisconnect(ChatUser? user) {
    if (user == null) return;

    // Aus Raum entfernen
    if (user.currentRoom != null) {
      _rooms[user.currentRoom]?.leave(user);
    }

    // Aus User-Liste entfernen
    _users.remove(user.id);

    print('User ${user.name} disconnected');
  }
}
```

### Server starten

```dart
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';

void main() async {
  final chatServer = ChatServer();

  final router = Router();

  // REST API für Infos
  router.get('/api/rooms', (Request request) async {
    return Response.ok(
      jsonEncode({
        'rooms': chatServer._rooms.keys.toList(),
      }),
      headers: {'content-type': 'application/json'},
    );
  });

  // WebSocket Endpoint
  router.get('/ws', webSocketHandler(chatServer.handleConnection));

  // CORS für Browser-Clients
  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(_corsMiddleware())
      .addHandler(router.call);

  final server = await io.serve(handler, 'localhost', 8080);
  print('Chat server running on http://localhost:${server.port}');
  print('WebSocket: ws://localhost:${server.port}/ws');
}

Middleware _corsMiddleware() {
  return (Handler innerHandler) {
    return (Request request) async {
      if (request.method == 'OPTIONS') {
        return Response.ok('', headers: _corsHeaders);
      }
      final response = await innerHandler(request);
      return response.change(headers: _corsHeaders);
    };
  };
}

const _corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type',
};
```

---

## Message-Protokoll Design

### JSON-basiertes Protokoll

```dart
// Basis Message-Struktur
abstract class WsMessage {
  String get type;
  Map<String, dynamic> toJson();
}

// Konkrete Messages
class AuthMessage extends WsMessage {
  final String name;
  final String? token;

  AuthMessage({required this.name, this.token});

  @override
  String get type => 'auth';

  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    'name': name,
    if (token != null) 'token': token,
  };

  factory AuthMessage.fromJson(Map<String, dynamic> json) {
    return AuthMessage(
      name: json['name'] as String,
      token: json['token'] as String?,
    );
  }
}

class ChatMessage extends WsMessage {
  final String text;
  final String? room;

  ChatMessage({required this.text, this.room});

  @override
  String get type => 'message';

  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    'text': text,
    if (room != null) 'room': room,
  };
}

// Message Factory
WsMessage parseMessage(String data) {
  final json = jsonDecode(data) as Map<String, dynamic>;
  final type = json['type'] as String;

  switch (type) {
    case 'auth':
      return AuthMessage.fromJson(json);
    case 'message':
      return ChatMessage.fromJson(json);
    default:
      throw FormatException('Unknown message type: $type');
  }
}
```

### Typed Message Handler

```dart
typedef MessageHandler<T extends WsMessage> = void Function(ChatUser user, T message);

class MessageRouter {
  final Map<String, Function> _handlers = {};

  void on<T extends WsMessage>(String type, MessageHandler<T> handler) {
    _handlers[type] = handler;
  }

  void handle(ChatUser user, Map<String, dynamic> json) {
    final type = json['type'] as String?;
    final handler = _handlers[type];

    if (handler == null) {
      user.sendError('Unknown message type: $type');
      return;
    }

    try {
      final message = parseMessage(jsonEncode(json));
      handler(user, message);
    } catch (e) {
      user.sendError('Invalid message: $e');
    }
  }
}

// Verwendung
final router = MessageRouter()
  ..on<AuthMessage>('auth', (user, msg) {
    // Handle auth
  })
  ..on<ChatMessage>('message', (user, msg) {
    // Handle message
  });
```

---

## Heartbeat & Connection Management

### Ping/Pong für Keep-Alive

```dart
import 'dart:async';

class ConnectionManager {
  final Duration pingInterval;
  final Duration timeout;
  final Map<String, Timer> _pingTimers = {};
  final Map<String, DateTime> _lastPong = {};

  ConnectionManager({
    this.pingInterval = const Duration(seconds: 30),
    this.timeout = const Duration(seconds: 60),
  });

  void startHeartbeat(ChatUser user) {
    _lastPong[user.id] = DateTime.now();

    _pingTimers[user.id] = Timer.periodic(pingInterval, (timer) {
      // Prüfen ob Timeout
      final lastPong = _lastPong[user.id];
      if (lastPong != null &&
          DateTime.now().difference(lastPong) > timeout) {
        print('User ${user.name} timed out');
        user.socket.sink.close(1000, 'Ping timeout');
        stopHeartbeat(user.id);
        return;
      }

      // Ping senden
      user.send({'type': 'ping', 'timestamp': DateTime.now().millisecondsSinceEpoch});
    });
  }

  void handlePong(String oderId) {
    _lastPong[userId] = DateTime.now();
  }

  void stopHeartbeat(String userId) {
    _pingTimers[userId]?.cancel();
    _pingTimers.remove(userId);
    _lastPong.remove(userId);
  }
}
```

### Reconnection auf Client-Seite

```dart
// Flutter/Dart Client
class WebSocketClient {
  WebSocketChannel? _channel;
  Timer? _reconnectTimer;
  final String url;
  final Duration reconnectDelay;
  bool _isConnecting = false;

  final StreamController<Map<String, dynamic>> _messageController =
      StreamController.broadcast();

  Stream<Map<String, dynamic>> get messages => _messageController.stream;

  WebSocketClient(this.url, {this.reconnectDelay = const Duration(seconds: 5)});

  Future<void> connect() async {
    if (_isConnecting) return;
    _isConnecting = true;

    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));

      _channel!.stream.listen(
        (data) {
          final message = jsonDecode(data as String);

          if (message['type'] == 'ping') {
            // Pong antworten
            send({'type': 'pong', 'timestamp': message['timestamp']});
          } else {
            _messageController.add(message);
          }
        },
        onDone: () {
          print('Connection closed, reconnecting...');
          _scheduleReconnect();
        },
        onError: (error) {
          print('Connection error: $error');
          _scheduleReconnect();
        },
      );

      _isConnecting = false;
    } catch (e) {
      _isConnecting = false;
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(reconnectDelay, connect);
  }

  void send(Map<String, dynamic> message) {
    _channel?.sink.add(jsonEncode(message));
  }

  void close() {
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _messageController.close();
  }
}
```

---

## Skalierung & Best Practices

### Mehrere Server-Instanzen

Für Skalierung mit mehreren Server-Instanzen braucht man einen Message Broker:

```
┌─────────┐    ┌─────────┐    ┌─────────┐
│ Server1 │    │ Server2 │    │ Server3 │
└────┬────┘    └────┬────┘    └────┬────┘
     │              │              │
     └──────────────┼──────────────┘
                    │
             ┌──────┴──────┐
             │    Redis    │
             │   Pub/Sub   │
             └─────────────┘
```

### Redis Pub/Sub Integration

```dart
import 'package:redis/redis.dart';

class ScalableChat {
  final RedisConnection _redisPub;
  final RedisConnection _redisSub;
  final ChatServer _localServer;

  ScalableChat(this._redisPub, this._redisSub, this._localServer);

  Future<void> start() async {
    // Subscribe to chat channel
    final pubsub = PubSub(await _redisSub.connect());

    pubsub.subscribe(['chat:messages']).listen((message) {
      final data = jsonDecode(message.message as String);
      _localServer.broadcastToRoom(data['room'], data);
    });
  }

  void publishMessage(String room, Map<String, dynamic> message) {
    // Publizieren für alle Server
    _redisPub.execute(['PUBLISH', 'chat:messages', jsonEncode({
      'room': room,
      ...message,
    })]);

    // Lokal auch senden (falls User auf diesem Server)
    _localServer.broadcastToRoom(room, message);
  }
}
```

### Best Practices

```dart
// 1. Nachrichten-Validierung
void validateMessage(Map<String, dynamic> message) {
  if (message['type'] == null) {
    throw FormatException('Message type required');
  }

  if (message['type'] == 'message') {
    final text = message['text'] as String?;
    if (text == null || text.isEmpty || text.length > 10000) {
      throw FormatException('Invalid message text');
    }
  }
}

// 2. Rate Limiting
class WebSocketRateLimiter {
  final int maxMessagesPerSecond;
  final Map<String, List<DateTime>> _messageLog = {};

  WebSocketRateLimiter({this.maxMessagesPerSecond = 10});

  bool allowMessage(String oderId) {
    final now = DateTime.now();
    final log = _messageLog.putIfAbsent(userId, () => []);

    // Alte Einträge entfernen
    log.removeWhere((time) => now.difference(time).inSeconds > 1);

    if (log.length >= maxMessagesPerSecond) {
      return false;
    }

    log.add(now);
    return true;
  }
}

// 3. Graceful Shutdown
Future<void> gracefulShutdown(HttpServer server, ChatServer chat) async {
  print('Shutting down...');

  // Allen Clients Bescheid geben
  for (final user in chat.users) {
    user.send({'type': 'server_shutdown'});
    user.socket.sink.close(1001, 'Server shutting down');
  }

  // Kurz warten
  await Future.delayed(Duration(seconds: 1));

  // Server stoppen
  await server.close();
}
```

---

## Zusammenfassung

- **WebSockets** ermöglichen bidirektionale Real-time-Kommunikation
- **shelf_web_socket** integriert WebSockets nahtlos in Shelf
- **Message-Protokoll** mit JSON für strukturierte Kommunikation
- **Rooms** für Gruppierung von Clients
- **Heartbeat** für Connection-Überwachung
- **Redis Pub/Sub** für Multi-Server-Skalierung

### Nächste Schritte

In der nächsten Einheit behandeln wir Background Jobs & Scheduling für asynchrone Aufgaben.
