# Getting Started with GadgetsOnline Microservices

## Quick Start

### 1. Build the Solution
```powershell
cd microservices
dotnet build
```

### 2. Start All Services (Easiest Method)
```powershell
.\start-all-services.ps1
```

This will open 4 PowerShell windows, one for each service:
- API Gateway: https://localhost:5000
- Catalog API: https://localhost:5001/swagger
- Cart API: https://localhost:5002/swagger
- Order API: https://localhost:5003/swagger

### 3. Test the APIs

#### Get All Products
```powershell
curl https://localhost:5000/api/products
```

#### Add Product to Cart
```powershell
curl -X POST https://localhost:5000/api/cart/user123/items `
  -H "Content-Type: application/json" `
  -d "1"
```

#### View Cart
```powershell
curl https://localhost:5000/api/cart/user123
```

#### Create Order
```powershell
$body = @{
    cartId = "user123"
    username = "john.doe"
    firstName = "John"
    lastName = "Doe"
    address = "123 Main St"
    city = "Seattle"
    state = "WA"
    postalCode = "98101"
    country = "USA"
    phone = "555-1234"
    email = "john@example.com"
} | ConvertTo-Json

curl -X POST https://localhost:5000/api/orders `
  -H "Content-Type: application/json" `
  -d $body
```

## Architecture Overview

```
┌─────────────┐
│   Client    │
└──────┬──────┘
       │
       ▼
┌─────────────────────┐
│   API Gateway       │  Port 5000
│   (Ocelot)          │
└──────┬──────────────┘
       │
       ├──────────────┬──────────────┬──────────────┐
       ▼              ▼              ▼              ▼
┌──────────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐
│ Catalog API  │ │ Cart API │ │Order API │ │          │
│ Port 5001    │ │Port 5002 │ │Port 5003 │ │          │
└──────┬───────┘ └────┬─────┘ └────┬─────┘ │          │
       │              │             │        │          │
       ▼              ▼             ▼        ▼          │
┌──────────────┐ ┌──────────┐ ┌──────────┐            │
│  CatalogDB   │ │  CartDB  │ │ OrderDB  │            │
└──────────────┘ └──────────┘ └──────────┘            │
```

## Service Responsibilities

### Catalog Service (Port 5001)
- Manages products and categories
- Provides product search and filtering
- Returns bestsellers

**Endpoints:**
- `GET /api/products` - All products
- `GET /api/products/{id}` - Product by ID
- `GET /api/products/bestsellers` - Top products
- `GET /api/categories` - All categories
- `GET /api/categories/{id}/products` - Products by category

### Cart Service (Port 5002)
- Manages shopping carts
- Adds/removes items
- Calculates totals
- Calls Catalog Service for product info

**Endpoints:**
- `GET /api/cart/{cartId}` - Get cart
- `POST /api/cart/{cartId}/items` - Add item
- `DELETE /api/cart/{cartId}/items/{productId}` - Remove item
- `GET /api/cart/{cartId}/total` - Get total
- `DELETE /api/cart/{cartId}` - Clear cart

### Order Service (Port 5003)
- Processes orders
- Stores order history
- Calls Cart Service to get cart items
- Clears cart after order creation

**Endpoints:**
- `POST /api/orders` - Create order
- `GET /api/orders/{id}` - Get order
- `GET /api/orders/user/{username}` - User's orders

### API Gateway (Port 5000)
- Single entry point for all requests
- Routes to appropriate microservice
- Handles CORS
- Can add authentication, rate limiting, etc.

## Database Configuration

Each service uses SQL Server LocalDB with its own database:

- **CatalogDB**: Products, Categories
- **CartDB**: Cart items
- **OrderDB**: Orders, Order details

Connection strings are in each service's `appsettings.json`.

## Development Tips

### Run Individual Service
```powershell
cd src/GadgetsOnline.Catalog.API
dotnet run
```

### Watch Mode (Auto-rebuild)
```powershell
cd src/GadgetsOnline.Catalog.API
dotnet watch run
```

### View Swagger Documentation
- Catalog: https://localhost:5001/swagger
- Cart: https://localhost:5002/swagger
- Order: https://localhost:5003/swagger

### Change Ports
Edit `Properties/launchSettings.json` in each service.

## Troubleshooting

### "Port already in use"
- Stop other services using those ports
- Or change ports in launchSettings.json

### "Cannot connect to database"
- Ensure SQL Server LocalDB is installed
- Run: `sqllocaldb start MSSQLLocalDB`

### "Service not responding"
- Check if all dependent services are running
- Cart needs Catalog
- Order needs Cart
- Gateway needs all three

### "CORS errors"
- All services have CORS enabled for development
- Check browser console for specific errors

## Next Steps

1. **Add Authentication**: Implement JWT or OAuth2
2. **Add Logging**: Use Serilog or NLog
3. **Add Monitoring**: Implement health checks
4. **Add Resilience**: Use Polly for retry policies
5. **Add Caching**: Use Redis for performance
6. **Add Message Queue**: RabbitMQ for async communication
7. **Containerize**: Create Dockerfiles for each service
8. **Deploy**: Use Kubernetes or Azure Container Apps

## Comparison: Monolith vs Microservices

### Monolith (Original)
- ✅ Simple to develop and deploy
- ✅ Easy to debug
- ❌ Single point of failure
- ❌ Must scale entire app
- ❌ Technology lock-in
- ❌ Long deployment times

### Microservices (New)
- ✅ Independent deployment
- ✅ Scale services independently
- ✅ Technology flexibility
- ✅ Fault isolation
- ✅ Team autonomy
- ❌ More complex infrastructure
- ❌ Distributed system challenges
- ❌ Network latency

## Support

For issues or questions, check:
- README.md for detailed documentation
- MICROSERVICES_MIGRATION_PLAN.md for architecture details
- Swagger UI for API documentation
