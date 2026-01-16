# Async Messaging Sequence Diagrams

## 1. OrderCreated Event - Cart Auto-Clear Flow

This diagram shows the complete flow of creating an order and automatically clearing the cart through RabbitMQ async messaging.

```mermaid
sequenceDiagram
    participant User
    participant WebUI as Web Frontend<br/>(Port 5100)
    participant Gateway as API Gateway<br/>(Port 5000)
    participant OrderAPI as Order API<br/>(Port 5003)
    participant OrderDB as Order Database<br/>(SQL Server)
    participant RabbitMQ as RabbitMQ Broker<br/>(Port 5672)
    participant CartAPI as Cart API<br/>(Port 5002)
    participant CartDB as Cart Database<br/>(SQL Server)

    Note over User,CartDB: User Journey: Create Order with Cart Items

    User->>WebUI: 1. Click "Place Order"
    activate WebUI
    
    WebUI->>Gateway: 2. POST /api/orders<br/>{username, items[]}
    activate Gateway
    
    Gateway->>OrderAPI: 3. POST /api/orders<br/>(Route to Order API)
    activate OrderAPI
    
    Note over OrderAPI: Validate order data
    
    OrderAPI->>OrderDB: 4. INSERT INTO Orders<br/>INSERT INTO OrderDetails
    activate OrderDB
    OrderDB-->>OrderAPI: 5. Order saved<br/>(OrderId: 2005)
    deactivate OrderDB
    
    Note over OrderAPI: Order created successfully
    
    OrderAPI->>RabbitMQ: 6. Publish OrderCreatedEvent<br/>{<br/>  OrderId: 2005,<br/>  Username: "testuser",<br/>  Total: 1698.00,<br/>  OrderDate: "2026-01-16",<br/>  Items: [...]<br/>}
    activate RabbitMQ
    
    Note over RabbitMQ: Message queued in<br/>OrderCreatedEvent exchange
    
    OrderAPI-->>Gateway: 7. 200 OK<br/>{orderId: 2005, total: 1698.00}
    deactivate OrderAPI
    
    Gateway-->>WebUI: 8. Order confirmation
    deactivate Gateway
    
    WebUI-->>User: 9. "Order placed successfully!"
    deactivate WebUI
    
    Note over RabbitMQ,CartAPI: Async Processing (happens independently)
    
    RabbitMQ->>CartAPI: 10. Deliver OrderCreatedEvent<br/>(Consumer: OrderCreatedConsumer)
    activate CartAPI
    deactivate RabbitMQ
    
    Note over CartAPI: Process event:<br/>Extract username from event
    
    CartAPI->>CartDB: 11. DELETE FROM Carts<br/>WHERE CartId = 'testuser'
    activate CartDB
    CartDB-->>CartAPI: 12. Cart deleted
    deactivate CartDB
    
    Note over CartAPI: Cart cleared successfully
    
    CartAPI->>CartAPI: 13. Log: "Cart cleared for user: testuser"
    deactivate CartAPI
    
    Note over User,CartDB: Result: Order created + Cart automatically cleared
```

---

## 2. Complete Flow with Cart Cleared Event (Future Enhancement)

This diagram shows the enhanced flow including the CartClearedEvent for audit/analytics purposes.

```mermaid
sequenceDiagram
    participant User
    participant WebUI as Web Frontend
    participant Gateway as API Gateway
    participant OrderAPI as Order API
    participant OrderDB as Order Database
    participant RabbitMQ as RabbitMQ Broker
    participant CartAPI as Cart API
    participant CartDB as Cart Database
    participant Analytics as Analytics Service<br/>(Future)

    Note over User,Analytics: Enhanced Flow with CartClearedEvent

    User->>WebUI: 1. Place Order
    WebUI->>Gateway: 2. POST /api/orders
    Gateway->>OrderAPI: 3. Create Order
    
    OrderAPI->>OrderDB: 4. Save Order
    OrderDB-->>OrderAPI: 5. Order Saved
    
    OrderAPI->>RabbitMQ: 6. Publish OrderCreatedEvent
    Note over RabbitMQ: Event: OrderCreated
    
    OrderAPI-->>Gateway: 7. Order Response
    Gateway-->>WebUI: 8. Success
    WebUI-->>User: 9. Order Confirmed
    
    rect rgb(200, 220, 250)
        Note over RabbitMQ,CartAPI: Async: Cart Clearing
        RabbitMQ->>CartAPI: 10. OrderCreatedEvent
        CartAPI->>CartDB: 11. Delete Cart
        CartDB-->>CartAPI: 12. Cart Deleted
        
        CartAPI->>RabbitMQ: 13. Publish CartClearedEvent<br/>{<br/>  CartId: "testuser",<br/>  ClearedAt: "2026-01-16",<br/>  Reason: "OrderCreated",<br/>  OrderId: 2005<br/>}
        Note over RabbitMQ: Event: CartCleared
    end
    
    rect rgb(250, 220, 200)
        Note over RabbitMQ,Analytics: Async: Analytics Processing
        RabbitMQ->>Analytics: 14. CartClearedEvent
        Analytics->>Analytics: 15. Log cart conversion<br/>Track order completion rate
        Note over Analytics: Metrics updated:<br/>- Cart abandonment rate<br/>- Order conversion rate
    end
    
    Note over User,Analytics: All events processed asynchronously
```

---

## 3. Detailed Event Flow with Timing

This diagram shows the timing and parallel processing nature of async events.

```mermaid
sequenceDiagram
    autonumber
    participant Client
    participant OrderAPI as Order API
    participant RabbitMQ
    participant CartAPI as Cart API
    participant NotificationSvc as Notification Service<br/>(Future)

    Note over Client,NotificationSvc: Parallel Event Processing

    Client->>OrderAPI: POST /api/orders
    activate OrderAPI
    
    OrderAPI->>OrderAPI: Validate & Save Order
    Note right of OrderAPI: Synchronous:<br/>~200ms
    
    OrderAPI->>RabbitMQ: Publish OrderCreatedEvent
    activate RabbitMQ
    Note right of RabbitMQ: Message persisted<br/>~5ms
    
    OrderAPI-->>Client: 200 OK (Order Created)
    deactivate OrderAPI
    Note right of Client: User sees success<br/>immediately
    
    par Parallel Processing
        RabbitMQ->>CartAPI: Deliver to Cart Consumer
        activate CartAPI
        Note right of CartAPI: Process: ~50ms
        CartAPI->>CartAPI: Clear Cart
        CartAPI-->>RabbitMQ: ACK
        deactivate CartAPI
    and
        RabbitMQ->>NotificationSvc: Deliver to Notification Consumer
        activate NotificationSvc
        Note right of NotificationSvc: Process: ~100ms
        NotificationSvc->>NotificationSvc: Send Email/SMS
        NotificationSvc-->>RabbitMQ: ACK
        deactivate NotificationSvc
    end
    
    deactivate RabbitMQ
    
    Note over Client,NotificationSvc: Total user-facing time: ~205ms<br/>Background processing: ~150ms (parallel)
```

---

## 4. Error Handling and Retry Flow

This diagram shows how RabbitMQ handles failures and retries.

```mermaid
sequenceDiagram
    participant OrderAPI as Order API
    participant RabbitMQ
    participant CartAPI as Cart API (Down)
    participant CartAPI2 as Cart API (Recovered)

    Note over OrderAPI,CartAPI2: Resilience: Service Failure Scenario

    OrderAPI->>RabbitMQ: 1. Publish OrderCreatedEvent
    activate RabbitMQ
    Note right of RabbitMQ: Message persisted<br/>in queue
    
    RabbitMQ->>CartAPI: 2. Attempt delivery
    activate CartAPI
    Note right of CartAPI: Service is down<br/>or crashed
    CartAPI--xRabbitMQ: 3. Connection failed
    deactivate CartAPI
    
    Note over RabbitMQ: Message remains in queue<br/>Retry after delay
    
    RabbitMQ->>RabbitMQ: 4. Wait (exponential backoff)
    Note right of RabbitMQ: Retry #1: 5 seconds<br/>Retry #2: 10 seconds<br/>Retry #3: 20 seconds
    
    Note over CartAPI2: Service recovers
    
    RabbitMQ->>CartAPI2: 5. Retry delivery
    activate CartAPI2
    CartAPI2->>CartAPI2: 6. Process event<br/>Clear cart
    CartAPI2-->>RabbitMQ: 7. ACK (Success)
    deactivate CartAPI2
    deactivate RabbitMQ
    
    Note over OrderAPI,CartAPI2: Message delivered successfully<br/>No data loss!
```

---

## 5. Multiple Consumers Pattern

This diagram shows how multiple services can consume the same event.

```mermaid
sequenceDiagram
    participant OrderAPI as Order API
    participant RabbitMQ
    participant CartAPI as Cart API
    participant EmailSvc as Email Service
    participant AnalyticsSvc as Analytics Service
    participant InventorySvc as Inventory Service

    Note over OrderAPI,InventorySvc: Fan-out Pattern: One Event, Multiple Consumers

    OrderAPI->>RabbitMQ: Publish OrderCreatedEvent
    activate RabbitMQ
    
    Note over RabbitMQ: Event copied to<br/>multiple queues
    
    par Consumer 1: Cart Service
        RabbitMQ->>CartAPI: OrderCreatedEvent
        activate CartAPI
        CartAPI->>CartAPI: Clear user's cart
        CartAPI-->>RabbitMQ: ACK
        deactivate CartAPI
    and Consumer 2: Email Service
        RabbitMQ->>EmailSvc: OrderCreatedEvent
        activate EmailSvc
        EmailSvc->>EmailSvc: Send confirmation email
        EmailSvc-->>RabbitMQ: ACK
        deactivate EmailSvc
    and Consumer 3: Analytics Service
        RabbitMQ->>AnalyticsSvc: OrderCreatedEvent
        activate AnalyticsSvc
        AnalyticsSvc->>AnalyticsSvc: Log order metrics
        AnalyticsSvc-->>RabbitMQ: ACK
        deactivate AnalyticsSvc
    and Consumer 4: Inventory Service
        RabbitMQ->>InventorySvc: OrderCreatedEvent
        activate InventorySvc
        InventorySvc->>InventorySvc: Reduce stock levels
        InventorySvc-->>RabbitMQ: ACK
        deactivate InventorySvc
    end
    
    deactivate RabbitMQ
    
    Note over OrderAPI,InventorySvc: All consumers process independently<br/>Failure in one doesn't affect others
```

---

## Key Benefits Illustrated

### 1. **Decoupling**
- Order API doesn't know about Cart API
- Services can be deployed independently
- Easy to add new consumers without changing publishers

### 2. **Resilience**
- Messages persist in RabbitMQ if consumer is down
- Automatic retry with exponential backoff
- No data loss even during service failures

### 3. **Scalability**
- Multiple consumers can process events in parallel
- Can add more consumer instances for load balancing
- Horizontal scaling without code changes

### 4. **Performance**
- User gets immediate response (synchronous part)
- Heavy processing happens asynchronously
- Better user experience with faster response times

---

## Event Schemas

### OrderCreatedEvent
```json
{
  "orderId": 2005,
  "username": "testuser",
  "total": 1698.00,
  "orderDate": "2026-01-16T06:07:27",
  "items": [
    {
      "productId": 1,
      "quantity": 1,
      "unitPrice": 699.00
    },
    {
      "productId": 2,
      "quantity": 1,
      "unitPrice": 999.00
    }
  ],
  "customerInfo": {
    "firstName": "Test",
    "lastName": "User",
    "email": "test@example.com",
    "phone": "555-0123"
  }
}
```

### CartClearedEvent (Planned)
```json
{
  "cartId": "testuser",
  "clearedAt": "2026-01-16T06:07:30",
  "reason": "OrderCreated",
  "orderId": 2005,
  "itemCount": 2
}
```

---

## Testing the Flow

### Test Script
```powershell
# Run the async messaging test
cd GadgetsOnlineWebForms/microservices
.\test-async-messaging.ps1
```

### Expected Output
1. Cart has 2 items
2. Order created (ID: 2005)
3. Wait 3 seconds for async processing
4. Cart is empty (cleared automatically)

### Verify in RabbitMQ UI
- URL: http://localhost:15672
- Username: guest
- Password: guest
- Check "Queues" tab for message activity
- Check "Exchanges" tab for OrderCreatedEvent

