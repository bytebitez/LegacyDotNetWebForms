# Microservices Interaction Diagram

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                            User / Browser                                    │
└────────────────────────────────┬────────────────────────────────────────────┘
                                 │ HTTP
                                 ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                         Blazor Web Frontend                                  │
│                           (Port: 5100)                                       │
└────────────────────────────────┬────────────────────────────────────────────┘
                                 │ HTTP
                                 ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                          API Gateway (Ocelot)                                │
│                            (Port: 5000)                                      │
│  Routes: /api/products, /api/cart, /api/orders                              │
└──────────┬──────────────────┬──────────────────┬───────────────────────────┘
           │                  │                  │
           │ HTTP             │ HTTP             │ HTTP
           ▼                  ▼                  ▼
┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐
│  Catalog API     │  │   Cart API       │  │   Order API      │
│  (Port: 5001)    │  │  (Port: 5002)    │  │  (Port: 5003)    │
│                  │  │                  │  │                  │
│  GET /products   │  │  GET /cart/{id}  │  │  POST /orders    │
│  GET /categories │  │  POST /items     │  │  GET /orders/{id}│
└────────┬─────────┘  └────────┬─────────┘  └────────┬─────────┘
         │                     │                     │
         │                     │                     │
         ▼                     ▼                     ▼
┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐
│   CatalogDB      │  │    CartDB        │  │    OrderDB       │
│  (SQL Server)    │  │  (SQL Server)    │  │  (SQL Server)    │
└──────────────────┘  └──────────────────┘  └──────────────────┘
```

## Synchronous Communication (HTTP/REST)

### 1. Cart API → Catalog API
**Purpose:** Get product information when adding items to cart

```
Flow:
1. User adds product to cart
2. Cart API receives: POST /api/cart/{cartId}/items
3. Cart API calls: GET http://catalog-api:5001/api/products/{productId}
4. Catalog API returns product details (name, price, stock)
5. Cart API validates and stores cart item
```

**Code Location:**
- `GadgetsOnline.Cart.API/Controllers/CartController.cs`
- Method: `AddItemToCart()`

---

### 2. Order API → Catalog API
**Purpose:** Validate products exist and get current prices when creating order

```
Flow:
1. User creates order
2. Order API receives: POST /api/orders
3. For each product in order:
   - Order API calls: GET http://catalog-api:5001/api/products/{productId}
   - Validates product exists and is available
4. Order API creates order with validated data
```

**Code Location:**
- `GadgetsOnline.Order.API/Controllers/OrdersController.cs`
- Method: `CreateOrder()`

---

### 3. Web Frontend → API Gateway → All Services
**Purpose:** Single entry point for all client requests

```
Flow:
1. Frontend makes request to API Gateway (Port 5000)
2. Gateway routes based on path:
   - /api/products/* → Catalog API (5001)
   - /api/cart/* → Cart API (5002)
   - /api/orders/* → Order API (5003)
3. Gateway returns response to frontend
```

**Code Location:**
- `GadgetsOnline.ApiGateway/ocelot.json`
- `GadgetsOnline.Web/Services/`

---

## Asynchronous Communication (RabbitMQ)

### Event Flow Architecture

```
                    ┌─────────────────────────────────────┐
                    │         RabbitMQ Broker             │
                    │        (Port: 5672)                 │
                    │   Management UI: 15672              │
                    └──────────┬──────────────────────────┘
                               │
                ┌──────────────┼──────────────┐
                │              │              │
                ▼              ▼              ▼
         [Exchange]      [Exchange]      [Exchange]
    OrderCreatedEvent  CartClearedEvent  InventoryUpdateEvent
                │              │              │
                ▼              ▼              ▼
           [Queue]        [Queue]        [Queue]
                │              │              │
                ▼              ▼              ▼
         [Consumer]      [Consumer]      [Consumer]
```

---

### 1. OrderCreatedEvent (✅ IMPLEMENTED)

**Publisher:** Order API  
**Consumer:** Cart API

```
Flow:
1. Order API creates new order
2. Order API publishes OrderCreatedEvent to RabbitMQ
   {
     "orderId": 2005,
     "username": "testuser",
     "total": 1698.00,
     "orderDate": "2026-01-16T06:07:27",
     "items": [...]
   }
3. RabbitMQ stores message in queue
4. Cart API consumer receives event
5. Cart API clears the user's cart automatically
```

**Code Locations:**
- Publisher: `GadgetsOnline.Order.API/Controllers/OrdersController.cs`
- Event: `GadgetsOnline.Shared.Contracts/Events/OrderCreatedEvent.cs`
- Consumer: `GadgetsOnline.Cart.API/Consumers/OrderCreatedConsumer.cs`

**Benefits:**
- Cart clears automatically without Order API knowing about Cart API
- If Cart API is down, message waits in queue
- Decoupled services

---

### 2. CartClearedEvent (📋 PLANNED)

**Publisher:** Cart API  
**Consumer:** Analytics/Logging Service (future)

```
Flow:
1. Cart API clears cart (after order or manual clear)
2. Cart API publishes CartClearedEvent
   {
     "cartId": "testuser",
     "clearedAt": "2026-01-16T06:07:30",
     "reason": "OrderCreated"
   }
3. Other services can react (logging, analytics, etc.)
```

**Use Cases:**
- Track cart abandonment vs. order completion
- Analytics on shopping behavior
- Audit trail

---

### 3. InventoryUpdateEvent (📋 PLANNED)

**Publisher:** Order API  
**Consumer:** Catalog API

```
Flow:
1. Order API creates order
2. Order API publishes InventoryUpdateEvent for each product
   {
     "productId": 1,
     "quantityChange": -2,
     "updatedAt": "2026-01-16T06:07:27"
   }
3. Catalog API receives event
4. Catalog API reduces product stock
   - Product 1: Stock 100 → 98
```

**Benefits:**
- Automatic inventory management
- Order API doesn't need direct access to Catalog DB
- Can add multiple consumers (warehouse, suppliers, etc.)

---

## Complete User Journey Example

### Scenario: User buys 2 products

```
Step 1: Browse Products
  User → Web → Gateway → Catalog API → CatalogDB
  ← Returns product list

Step 2: Add to Cart
  User → Web → Gateway → Cart API → Catalog API (validate product)
  Cart API → CartDB (store cart item)
  ← Returns updated cart

Step 3: Create Order
  User → Web → Gateway → Order API
  Order API → Catalog API (validate products)
  Order API → OrderDB (create order)
  Order API → RabbitMQ (publish OrderCreatedEvent) ✅ ASYNC
  ← Returns order confirmation

Step 4: Cart Auto-Clear (Async)
  RabbitMQ → Cart API Consumer
  Cart API → CartDB (delete cart)
  Cart API → RabbitMQ (publish CartClearedEvent) 📋 PLANNED

Step 5: Inventory Update (Async)
  RabbitMQ → Catalog API Consumer 📋 PLANNED
  Catalog API → CatalogDB (reduce stock)
```

---

## Communication Patterns Summary

| From Service | To Service | Type | Purpose | Status |
|--------------|------------|------|---------|--------|
| Web Frontend | API Gateway | HTTP | All requests | ✅ |
| API Gateway | Catalog API | HTTP | Route products requests | ✅ |
| API Gateway | Cart API | HTTP | Route cart requests | ✅ |
| API Gateway | Order API | HTTP | Route order requests | ✅ |
| Cart API | Catalog API | HTTP | Validate products | ✅ |
| Order API | Catalog API | HTTP | Validate products | ✅ |
| Order API | Cart API | RabbitMQ | Clear cart after order | ✅ |
| Cart API | Analytics | RabbitMQ | Cart cleared event | 📋 |
| Order API | Catalog API | RabbitMQ | Update inventory | 📋 |

---

## Service Dependencies

### Catalog API
- **Depends on:** CatalogDB
- **Called by:** Cart API, Order API, API Gateway
- **Publishes:** None (yet)
- **Consumes:** InventoryUpdateEvent (planned)

### Cart API
- **Depends on:** CatalogDB (via HTTP), CartDB, RabbitMQ
- **Called by:** API Gateway
- **Publishes:** CartClearedEvent (planned)
- **Consumes:** OrderCreatedEvent ✅

### Order API
- **Depends on:** CatalogDB (via HTTP), OrderDB, RabbitMQ
- **Called by:** API Gateway
- **Publishes:** OrderCreatedEvent ✅, InventoryUpdateEvent (planned)
- **Consumes:** None

### API Gateway
- **Depends on:** All microservices
- **Called by:** Web Frontend
- **Publishes:** None
- **Consumes:** None

---

## Testing the Interactions

### Test Synchronous Communication
```powershell
# Test Catalog API directly
Invoke-RestMethod -Uri "http://localhost:5001/api/products" -Method GET

# Test through API Gateway
Invoke-RestMethod -Uri "http://localhost:5000/api/products" -Method GET

# Test Cart → Catalog interaction
Invoke-RestMethod -Uri "http://localhost:5000/api/cart/testuser/items" `
    -Method POST -ContentType "application/json" -Body '1'
```

### Test Asynchronous Communication
```powershell
# Run the async messaging test
.\test-async-messaging.ps1

# Check RabbitMQ Management UI
# http://localhost:15672 (guest/guest)
```

---

## Configuration Files

### RabbitMQ Connection Strings
- **Order API:** `appsettings.json` → `RabbitMQ:Host`
- **Cart API:** `appsettings.json` → `RabbitMQ:Host`
- **Docker:** `docker-compose.yml` → `RABBITMQ__HOST` environment variable

### Service URLs
- **Cart API:** `appsettings.json` → `CatalogApiUrl`
- **Order API:** `appsettings.json` → `CatalogApiUrl`
- **API Gateway:** `ocelot.json` → Downstream host configurations

---

## Next Steps

1. ✅ **Completed:** OrderCreatedEvent flow
2. 📋 **Implement:** InventoryUpdateEvent
3. 📋 **Implement:** CartClearedEvent
4. 📋 **Add:** Saga pattern for distributed transactions
5. 📋 **Add:** Circuit breaker for HTTP calls
6. 📋 **Add:** Distributed tracing (OpenTelemetry)

