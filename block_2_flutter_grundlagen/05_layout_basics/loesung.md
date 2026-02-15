# Lösung 2.5: Layout Basics

---

## Aufgabe 1

```dart
class SocialPost extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(child: Icon(Icons.person)),
              SizedBox(width: 12),
              Expanded(child: Text('username', style: TextStyle(fontWeight: FontWeight.bold))),
              IconButton(icon: Icon(Icons.more_horiz), onPressed: () {}),
            ],
          ),
        ),
        // Bild
        Image.network('https://picsum.photos/400/400', fit: BoxFit.cover),
        // Actions
        Row(
          children: [
            IconButton(icon: Icon(Icons.favorite_border), onPressed: () {}),
            IconButton(icon: Icon(Icons.chat_bubble_outline), onPressed: () {}),
            IconButton(icon: Icon(Icons.send), onPressed: () {}),
            Spacer(),
            IconButton(icon: Icon(Icons.bookmark_border), onPressed: () {}),
          ],
        ),
        // Likes & Beschreibung
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('1.234 Likes', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text('Beschreibungstext hier...'),
            ],
          ),
        ),
      ],
    );
  }
}
```

---

## Aufgabe 3

```dart
class BadgeIcon extends StatelessWidget {
  final IconData icon;
  final int count;

  const BadgeIcon({super.key, required this.icon, required this.count});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon, size: 32),
        if (count > 0)
          Positioned(
            right: -8,
            top: -8,
            child: Container(
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: BoxConstraints(minWidth: 20, minHeight: 20),
              child: Text(
                count > 99 ? '99+' : '$count',
                style: TextStyle(color: Colors.white, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
```
