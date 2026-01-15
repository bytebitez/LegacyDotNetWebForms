# GadgetsOnline Microservices Architecture

This is a microservices-based e-commerce application converted from a monolithic ASP.NET application.

## Architecture Overview

### Microservices
1. **Catalog Service** (Port 5001) - Manages products and categories
2. **Cart Service** (Port 5002) - Handles shopping cart operations
3. **Order Service** (Port 5003) - Processes orders
4. **API Gateway** (Port 5000) - Single entry point using Ocelot

### Communication
- **Synchronous**: HTTP/REST between services
- **Database per Service**: Each microservice has its own database
- **API Gateway**: Routes all client requests to appropriate services

## Project Structure

```
microservices/
├── src/
│   ├── GadgetsOnline.Catalog.API/      # Product catalog service
│   ├── GadgetsOnline.Cart.API/         # Shopping cart service
│   ├── GadgetsOnline.Order.API/        # Order processing service
│   ├── GadgetsOnline.ApiGateway/       # API Gateway (Ocelot)
│   └── GadgetsOnline.Shared.Contracts/ # Shared DTOs
├── docker-compose.yml
└── README.md
```

## Running Locally

### Prerequisites
- .NET 9.0 SDK
- SQL Server LocalDB or SQL Server

### Option 1: Run Individual Services

1. **Start Catalog Service**
   ```bash
   cd src/GadgetsOnline.Catalog.API
   dotnet run
   ```
   Access Swagger: https://localhost:5001/swagger

2. **Start Cart Service**
   ```bash
   cd src/GadgetsOnline.Cart.API
   dotnet run
   ```
   Access Swagger: https://localhost:5002/swagger

3. **Start Order Service**
   ```bash
   cd src/GadgetsOnline.Order.API
   dotnet run
   ```
   Access Swagger: https://localhost:5003/swagger

4. **Start API Gateway**
   ```bash
   cd src/GadgetsOnline.ApiGateway
   dotnet run
   ```
   Access Gateway: https://localhost:5000

### Option 2: Run with Docker Compose

```bash
docker-compose up --build
```

## API Endpoints

### Through API Gateway (https://localhost:5000)

#### Catalog Endpoints
- `GET /api/products` - Get all products
- `GET /api/products/{id}` - Get product by ID
- `GET /api/products/bestsellers?count=5` - Get bestsellers
- `GET /api/categories` - Get all categories
- `GET /api/categories/{id}/products` - Get products by category

#### Cart Endpoints
- `GET /api/cart/{cartId}` - Get cart
- `POST /api/cart/{cartId}/items` - Add item to cart (body: productId as int)
- `DELETE /api/cart/{cartId}/items/{productId}` - Remove item from cart
- `GET /api/cart/{cartId}/total` - Get cart total
- `DELETE /api/cart/{cartId}` - Clear cart

#### Order Endpoints
- `POST /api/orders` - Create order
- `GET /api/orders/{id}` - Get order by ID
- `GET /api/orders/user/{username}` - Get orders by user

## Testing the Services

### 1. Get Products
```bash
curl https://localhost:5000/api/products
```

### 2. Add to Cart
```bash
curl -X POST https://localhost:5000/api/cart/user123/items \
  -H "Content-Type: application/json" \
  -d "1"
```

### 3. View Cart
```bash
curl https://localhost:5000/api/cart/user123
```

### 4. Create Order
```bash
curl -X POST https://localhost:5000/api/orders \
  -H "Content-Type: application/json" \
  -d '{
    "cartId": "user123",
    "username": "john.doe",
    "firstName": "John",
    "lastName": "Doe",
    "address": "123 Main St",
    "city": "Seattle",
    "state": "WA",
    "postalCode": "98101",
    "country": "USA",
    "phone": "555-1234",
    "email": "john@example.com"
  }'
```

## Database Configuration

Each service uses its own database:
- **CatalogDB** - Products and Categories
- **CartDB** - Shopping cart items
- **OrderDB** - Orders and order details

Connection strings are in each service's `appsettings.json`.

## Migration from Monolith

### What Changed
1. **Separated Concerns**: Split into 3 bounded contexts (Catalog, Cart, Order)
2. **Database per Service**: Each service owns its data
3. **API Gateway**: Single entry point for all requests
4. **Service Communication**: Services call each other via HTTP
5. **Shared Contracts**: Common DTOs in separate library

### Benefits
- **Independent Deployment**: Deploy services separately
- **Technology Flexibility**: Each service can use different tech stack
- **Scalability**: Scale services independently based on load
- **Fault Isolation**: Failure in one service doesn't crash entire app
- **Team Autonomy**: Different teams can own different services

### Next Steps
1. Add message broker (RabbitMQ/Azure Service Bus) for async communication
2. Implement distributed tracing (OpenTelemetry)
3. Add centralized logging (ELK Stack/Seq)
4. Implement circuit breakers (Polly)
5. Add authentication/authorization (IdentityServer/Azure AD)
6. Implement health checks
7. Add API versioning
8. Deploy to Kubernetes

## Development

### Build All Projects
```bash
dotnet build GadgetsOnline.Microservices.sln
```

### Run Tests
```bash
dotnet test
```

### Add New Service
1. Create new Web API project
2. Add reference to Shared.Contracts
3. Configure database and dependencies
4. Update API Gateway ocelot.json
5. Add to docker-compose.yml

## Troubleshooting

### Port Already in Use
Change ports in `Properties/launchSettings.json` for each service.

### Database Connection Issues
Ensure SQL Server LocalDB is running or update connection strings.

### Service Communication Errors
Verify all services are running and URLs in appsettings.json are correct.
