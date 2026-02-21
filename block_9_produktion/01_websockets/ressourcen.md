# Ressourcen: WebSockets & Real-time

## Offizielle Dokumentation

- [shelf_web_socket Package](https://pub.dev/packages/shelf_web_socket)
- [web_socket_channel Package](https://pub.dev/packages/web_socket_channel)
- [WebSocket Protocol RFC 6455](https://tools.ietf.org/html/rfc6455)
- [MDN WebSocket API](https://developer.mozilla.org/en-US/docs/Web/API/WebSocket)

## Cheat Sheet: WebSocket Handler

```dart
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

// Einfacher Handler
final handler = webSocketHandler((WebSocketChannel socket) {
  // Nachricht senden
  socket.sink.add('Hello');
  socket.sink.add(jsonEncode({'type': 'welcome'}));

  // Auf Nachrichten hören
  socket.stream.listen(
    (message) => print('Received: $message'),
    onDone: () => print('Disconnected'),
    onError: (e) => print('Error: $e'),
  );
});

// Mit Router
router.get('/ws', webSocketHandler(handleConnection));
```

## Cheat Sheet: Message Protocol

```dart
// Standard Message Format
{
  "type": "message_type",
  "payload": { ... },
  "timestamp": "2024-01-01T12:00:00Z"
}

// Client → Server Messages
{"type": "auth", "token": "..."}
{"type": "subscribe", "channel": "news"}
{"type": "unsubscribe", "channel": "news"}
{"type": "message", "text": "Hello"}
{"type": "ping"}

// Server → Client Messages
{"type": "welcome", "clientId": "..."}
{"type": "subscribed", "channel": "news"}
{"type": "notification", "channel": "news", "data": {...}}
{"type": "error", "message": "..."}
{"type": "pong"}
```

## Cheat Sheet: Connection Management

```dart
class ConnectionManager {
  final Map<String, WebSocketChannel> _clients = {};

  // Client hinzufügen
  void add(String id, WebSocketChannel socket) {
    _clients[id] = socket;
  }

  // Client entfernen
  void remove(String id) {
    _clients.remove(id);
  }

  // An alle senden
  void broadcast(String message) {
    for (final socket in _clients.values) {
      socket.sink.add(message);
    }
  }

  // An bestimmten Client
  void sendTo(String id, String message) {
    _clients[id]?.sink.add(message);
  }

  // An alle außer einem
  void broadcastExcept(String excludeId, String message) {
    for (final entry in _clients.entries) {
      if (entry.key != excludeId) {
        entry.value.sink.add(message);
      }
    }
  }
}
```

## Cheat Sheet: Channel/Room Pattern

```dart
class Room {
  final String name;
  final Set<String> members = {};

  void join(String clientId) => members.add(clientId);
  void leave(String clientId) => members.remove(clientId);
  bool hasMember(String id) => members.contains(id);
}

class RoomManager {
  final Map<String, Room> _rooms = {};
  final ConnectionManager _connections;

  void join(String clientId, String roomName) {
    final room = _rooms.putIfAbsent(roomName, () => Room(roomName));
    room.join(clientId);
  }

  void broadcast(String roomName, String message) {
    final room = _rooms[roomName];
    if (room == null) return;

    for (final memberId in room.members) {
      _connections.sendTo(memberId, message);
    }
  }
}
```

## Cheat Sheet: Heartbeat

```dart
// Server-seitig
Timer.periodic(Duration(seconds: 30), (_) {
  for (final client in clients) {
    client.send({'type': 'ping'});
  }
});

// Timeout prüfen
if (DateTime.now().difference(lastPong) > Duration(seconds: 60)) {
  client.socket.sink.close(1000, 'Timeout');
}

// Client-seitig
socket.stream.listen((data) {
  final msg = jsonDecode(data);
  if (msg['type'] == 'ping') {
    socket.sink.add(jsonEncode({'type': 'pong'}));
  }
});
```

## Cheat Sheet: Reconnection (Client)

```dart
class ReconnectingWebSocket {
  WebSocketChannel? _channel;
  final String url;
  int _retryCount = 0;
  final int maxRetries = 5;
  final Duration baseDelay = Duration(seconds: 1);

  Future<void> connect() async {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));
      _retryCount = 0;

      _channel!.stream.listen(
        onMessage,
        onDone: _reconnect,
        onError: (_) => _reconnect(),
      );
    } catch (e) {
      _reconnect();
    }
  }

  void _reconnect() {
    if (_retryCount >= maxRetries) {
      print('Max retries reached');
      return;
    }

    // Exponential Backoff
    final delay = baseDelay * (1 << _retryCount);
    _retryCount++;

    print('Reconnecting in ${delay.inSeconds}s...');
    Future.delayed(delay, connect);
  }
}
```

## Cheat Sheet: Close Codes

```dart
// Standard Close Codes
const CLOSE_NORMAL = 1000;        // Normale Beendigung
const CLOSE_GOING_AWAY = 1001;    // Server/Client geht offline
const CLOSE_PROTOCOL_ERROR = 1002; // Protokollfehler
const CLOSE_UNSUPPORTED = 1003;   // Nicht unterstützter Datentyp
const CLOSE_NO_STATUS = 1005;     // Kein Status (reserviert)
const CLOSE_ABNORMAL = 1006;      // Abnormaler Abbruch
const CLOSE_INVALID_DATA = 1007;  // Ungültige Daten
const CLOSE_POLICY = 1008;        // Policy-Verletzung
const CLOSE_TOO_LARGE = 1009;     // Nachricht zu groß
const CLOSE_EXTENSION = 1010;     // Extension fehlt
const CLOSE_INTERNAL = 1011;      // Interner Fehler

// Verbindung schließen
socket.sink.close(1000, 'Normal closure');
```

## Cheat Sheet: Flutter WebSocket Client

```dart
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get messages => _messageController.stream;

  void connect(String url) {
    _channel = WebSocketChannel.connect(Uri.parse(url));

    _channel!.stream.listen(
      (data) {
        final message = jsonDecode(data);
        _messageController.add(message);
      },
      onError: (e) => _messageController.addError(e),
    );
  }

  void send(Map<String, dynamic> message) {
    _channel?.sink.add(jsonEncode(message));
  }

  void dispose() {
    _channel?.sink.close();
    _messageController.close();
  }
}

// In Widget verwenden
class ChatWidget extends StatefulWidget {
  @override
  _ChatWidgetState createState() => _ChatWidgetState();
}

class _ChatWidgetState extends State<ChatWidget> {
  final _ws = WebSocketService();

  @override
  void initState() {
    super.initState();
    _ws.connect('ws://localhost:8080/ws');
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: _ws.messages,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Text('Message: ${snapshot.data}');
        }
        return CircularProgressIndicator();
      },
    );
  }

  @override
  void dispose() {
    _ws.dispose();
    super.dispose();
  }
}
```

## Best Practices

### DO

1. **Strukturiertes Message-Format** - JSON mit type-Feld
2. **Heartbeat implementieren** - Connection-Health prüfen
3. **Reconnection-Logik** - Mit Exponential Backoff
4. **Graceful Shutdown** - Clients benachrichtigen
5. **Rate Limiting** - Spam verhindern
6. **Message Validation** - Input prüfen
7. **Error Handling** - Fehler abfangen und loggen

### DON'T

1. **Große Payloads** - WebSocket für kleine Nachrichten
2. **Synchrone Operationen** - Blockiert Event Loop
3. **Sensitive Daten unverschlüsselt** - WSS verwenden
4. **Unbegrenzter History** - Memory Leaks
5. **Fehlende Timeouts** - Zombie Connections

## Skalierung mit Redis

```dart
// Pub/Sub für Multi-Server
import 'package:redis/redis.dart';

class ScalableNotifications {
  late RedisConnection _pub;
  late RedisConnection _sub;

  Future<void> init() async {
    _pub = await RedisConnection.connect('localhost', 6379);
    _sub = await RedisConnection.connect('localhost', 6379);

    // Subscribe
    final pubsub = PubSub(_sub);
    pubsub.subscribe(['notifications']).listen((msg) {
      // An lokale Clients weiterleiten
      localBroadcast(msg.message);
    });
  }

  void publish(String channel, Map<String, dynamic> message) {
    _pub.execute(['PUBLISH', channel, jsonEncode(message)]);
  }
}
```

## Testing WebSockets

```dart
import 'package:test/test.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() {
  test('WebSocket echo', () async {
    final channel = WebSocketChannel.connect(
      Uri.parse('ws://localhost:8080/ws'),
    );

    // Nachricht senden
    channel.sink.add('Hello');

    // Antwort erwarten
    final response = await channel.stream.first;
    expect(response, contains('Hello'));

    await channel.sink.close();
  });
}
```

## Tools

- **websocat** - WebSocket CLI Client
  ```bash
  cargo install websocat
  websocat ws://localhost:8080/ws
  ```

- **wscat** - Node.js WebSocket Client
  ```bash
  npm install -g wscat
  wscat -c ws://localhost:8080/ws
  ```

- **Postman** - WebSocket Support in neueren Versionen

- **Browser DevTools** - Network Tab → WS Filter
