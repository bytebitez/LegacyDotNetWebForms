# Microservices Migration Plan

## Current Monolithic Architecture
- Single ASP.NET Blazor application
- Shared database (GadgetsOnlineWebFormsDB)
- Tightly coupled services and models

## Target Microservices Architecture

### 1. Catalog Service
**Responsibility**: Product and category management
- Endpoints:
  - GET /api/products
  - GET /api/products/{id}
  - GET /api/products/bestsellers
  - GET /api/categories
  - GET /api/categories/{id}/products
- Database: CatalogDB (Products, Categories)
- Port: 5001

### 2. Cart Service
**Responsibility**: Shopping cart operations
- Endpoints:
  - GET /api/cart/{cartId}
  - POST /api/cart/{cartId}/items
  - DELETE /api/cart/{cartId}/items/{productId}
  - GET /api/cart/{cartId}/total
- Database: CartDB (Carts)
- Port: 5002
- Dependencies: Calls Catalog Service for product info

### 3. Order Service
**Responsibility**: Order processing and history
- Endpoints:
  - POST /api/orders
  - GET /api/orders/{id}
  - GET /api/orders/user/{username}
- Database: OrderDB (Orders, OrderDetails)
- Port: 5003
- Dependencies: Calls Catalog Service for product validation

### 4. API Gateway
**Responsibility**: Single entry point, routing, authentication
- Port: 5000
- Routes requests to appropriate microservices
- Handles cross-cutting concerns (logging, auth, rate limiting)

### 5. Web Frontend (Blazor)
**Responsibility**: User interface
- Communicates only with API Gateway
- Port: 5100

## Communication Patterns
- **Synchronous**: HTTP/REST for queries
- **Asynchronous**: Message queue (RabbitMQ/Azure Service Bus) for events
  - OrderCreated event
  - CartEmptied event

## Database Strategy
- **Database per Service** pattern
- Each microservice owns its data
- No shared database access

## Migration Steps
1. Create shared contracts library
2. Build Catalog Service
3. Build Cart Service
4. Build Order Service
5. Implement API Gateway
6. Refactor Blazor frontend
7. Add message broker for async communication
8. Implement distributed tracing and logging
9. Add health checks and monitoring
10. Deploy to containers (Docker/Kubernetes)
