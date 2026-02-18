# Übung 6.1: REST-Prinzipien & API-Design

## Ziel

Entwirf und implementiere eine RESTful API für einen Online-Shop mit korrekten Ressourcen-Namen, HTTP-Methoden und Statuscodes.

---

## Aufgabe 1: API-Design (15 min)

Entwirf die API-Struktur für einen Online-Shop mit folgenden Entitäten:
- Produkte (Products)
- Kategorien (Categories)
- Bestellungen (Orders)
- Bestellpositionen (Order Items)

### Anforderungen

Schreibe für jede Entität die REST-Endpunkte auf:

| Aktion | Methode | Pfad | Statuscode |
|--------|---------|------|------------|
| Alle Produkte | ? | ? | ? |
| Ein Produkt | ? | ? | ? |
| Produkt erstellen | ? | ? | ? |
| ... | ... | ... | ... |

### Zusätzliche Endpunkte

- Produkte einer Kategorie
- Bestellungen eines Kunden
- Positionen einer Bestellung

---

## Aufgabe 2: Basis-Implementation (20 min)

Implementiere die Produkt-Endpunkte.

### Datenmodell

```dart
class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String categoryId;
  final int stock;
  final DateTime createdAt;
}
```

### Endpunkte

```dart
GET    /api/v1/products          // Alle Produkte
GET    /api/v1/products/:id      // Ein Produkt
POST   /api/v1/products          // Produkt erstellen
PUT    /api/v1/products/:id      // Produkt ersetzen
PATCH  /api/v1/products/:id      // Produkt aktualisieren
DELETE /api/v1/products/:id      // Produkt löschen
```

### Korrekte Statuscodes

- GET Liste: 200 OK
- GET Einzeln: 200 OK oder 404 Not Found
- POST: 201 Created mit Location-Header
- PUT/PATCH: 200 OK oder 404 Not Found
- DELETE: 204 No Content oder 404 Not Found

---

## Aufgabe 3: Verschachtelte Ressourcen (15 min)

Implementiere verschachtelte Ressourcen.

### Kategorie-Produkte

```dart
GET /api/v1/categories/:categoryId/products
```

Liefert alle Produkte einer Kategorie.

### Response

```json
{
  "category": {
    "id": "electronics",
    "name": "Elektronik"
  },
  "products": [
    {"id": "1", "name": "Laptop", "price": 999.99},
    {"id": "2", "name": "Smartphone", "price": 599.99}
  ],
  "total": 2
}
```

---

## Aufgabe 4: API-Versionierung (10 min)

Implementiere zwei API-Versionen.

### v1: Einfache Produktliste

```json
{
  "products": [
    {"id": "1", "name": "Laptop", "price": 999.99}
  ]
}
```

### v2: Mit Pagination und Meta-Daten

```json
{
  "data": [
    {"id": "1", "name": "Laptop", "price": 999.99}
  ],
  "meta": {
    "total": 50,
    "page": 1,
    "perPage": 10,
    "totalPages": 5
  },
  "links": {
    "self": "/api/v2/products?page=1",
    "next": "/api/v2/products?page=2",
    "last": "/api/v2/products?page=5"
  }
}
```

---

## Aufgabe 5: Location-Header (5 min)

Bei POST-Requests soll der `Location`-Header gesetzt werden.

### Request

```
POST /api/v1/products
Content-Type: application/json

{"name": "Neues Produkt", "price": 49.99}
```

### Response

```
HTTP/1.1 201 Created
Location: /api/v1/products/123
Content-Type: application/json

{"id": "123", "name": "Neues Produkt", "price": 49.99, ...}
```

---

## Testen

```bash
# Alle Produkte
curl http://localhost:8080/api/v1/products

# Ein Produkt
curl http://localhost:8080/api/v1/products/1

# Produkt erstellen
curl -X POST http://localhost:8080/api/v1/products \
  -H "Content-Type: application/json" \
  -d '{"name": "Tablet", "price": 399.99, "categoryId": "electronics"}'

# Produkt aktualisieren (PATCH)
curl -X PATCH http://localhost:8080/api/v1/products/1 \
  -H "Content-Type: application/json" \
  -d '{"price": 899.99}'

# Produkt ersetzen (PUT)
curl -X PUT http://localhost:8080/api/v1/products/1 \
  -H "Content-Type: application/json" \
  -d '{"name": "Laptop Pro", "price": 1299.99, "categoryId": "electronics", "stock": 50}'

# Produkt löschen
curl -X DELETE http://localhost:8080/api/v1/products/1

# Produkte einer Kategorie
curl http://localhost:8080/api/v1/categories/electronics/products

# API v2 mit Pagination
curl "http://localhost:8080/api/v2/products?page=1&perPage=10"

# Location-Header prüfen
curl -i -X POST http://localhost:8080/api/v1/products \
  -H "Content-Type: application/json" \
  -d '{"name": "Test"}'
```

---

## Abgabe-Checkliste

- [ ] Alle CRUD-Endpunkte für Produkte
- [ ] Korrekte HTTP-Methoden
- [ ] Korrekte Statuscodes (200, 201, 204, 404)
- [ ] Verschachtelte Ressourcen funktionieren
- [ ] Zwei API-Versionen (v1, v2)
- [ ] Location-Header bei POST
- [ ] Konsistente Response-Struktur
