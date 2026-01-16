# Simple Async Messaging Diagram

## High-Level: Order → Cart Async Communication

```mermaid
sequenceDiagram
    participant User
    participant OrderAPI as Order Service
    participant RabbitMQ
    participant CartAPI as Cart Service

    User->>OrderAPI: Create Order
    OrderAPI->>OrderAPI: Save Order to DB
    OrderAPI-->>User: Order Confirmed
    
    OrderAPI->>RabbitMQ: OrderCreatedEvent
    Note over RabbitMQ: Message Queue
    
    RabbitMQ->>CartAPI: OrderCreatedEvent
    CartAPI->>CartAPI: Clear Cart from DB
    
    Note over OrderAPI,CartAPI: Services communicate asynchronously
```

---

## Even Simpler: Component View

```mermaid
graph LR
    A[Order Service] -->|Publish: OrderCreatedEvent| B[RabbitMQ]
    B -->|Consume: OrderCreatedEvent| C[Cart Service]
    
    style A fill:#e1f5ff
    style B fill:#fff4e1
    style C fill:#e8f5e9
```

---

## Flow Summary

1. **Order Service** creates order → publishes event to RabbitMQ
2. **RabbitMQ** stores and delivers the event
3. **Cart Service** receives event → clears the cart

**Key Point:** Services don't talk directly to each other - they communicate through RabbitMQ messages.
