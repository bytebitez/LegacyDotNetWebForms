# Swagger API Documentation Guide

## Overview

Swagger (OpenAPI) provides interactive API documentation for all three backend microservices. You can view API endpoints, test them directly from your browser, and see request/response schemas.

## Accessing Swagger UI

### Catalog API
```
http://localhost:5001/swagger
```
**Available Endpoints:**
- GET /api/products - Get all products
- GET /api/products/{id} - Get product by ID
- GET /api/products/bestsellers - Get bestseller products
- GET /api/categories - Get all categories
- GET /api/categories/{id}/products - Get products by category

### Cart API
```
http://localhost:5002/swagger
```
**Available Endpoints:**
- GET /api/cart/{userId} - Get user's cart
- POST /api/cart/{userId}/items - Add item to cart
- PUT /api/cart/{userId}/items/{productId} - Update cart item quantity
- DELETE /api/cart/{userId}/items/{productId} - Remove item from cart
- DELETE /api/cart/{userId} - Clear entire cart

### Order API
```
http://localhost:5003/swagger
```
**Available Endpoints:**
- GET /api/orders/{userId} - Get user's orders
- POST /api/orders - Create new order
- GET /api/orders/{userId}/{orderId} - Get specific order details

## How to Use Swagger UI

### 1. View API Endpoints
- Open any Swagger URL in your browser
- You'll see a list of all available endpoints grouped by controller
- Click on any endpoint to expand and see details

### 2. Test an Endpoint
1. Click on an endpoint to expand it
2. Click the "Try it out" button
3. Fill in any required parameters
4. Click "Execute"
5. View the response below

### 3. View Request/Response Schemas
- Each endpoint shows the expected request body format
- Response schemas show what data you'll receive
- Example values are provided for reference

## Example: Testing the Catalog API

### Get All Products
1. Open http://localhost:5001/swagger
2. Find `GET /api/products`
3. Click "Try it out"
4. Click "Execute"
5. You should see a 200 response with all 13 products

### Get Products by Category
1. Find `GET /api/categories/{id}/products`
2. Click "Try it out"
3. Enter `1` for the id parameter (Mobile Phones)
4. Click "Execute"
5. You should see all mobile phone products

## Example: Testing the Cart API

### Add Item to Cart
1. Open http://localhost:5002/swagger
2. Find `POST /api/cart/{userId}/items`
3. Click "Try it out"
4. Enter `user123` for userId
5. In the request body, enter:
```json
{
  "productId": 1,
  "quantity": 2
}
```
6. Click "Execute"
7. You should see a 200 response with the updated cart

## Example: Testing the Order API

### Create an Order
1. Open http://localhost:5003/swagger
2. Find `POST /api/orders`
3. Click "Try it out"
4. In the request body, enter:
```json
{
  "userId": "user123",
  "firstName": "John",
  "lastName": "Doe",
  "address": "123 Main St",
  "city": "Seattle",
  "state": "WA",
  "postalCode": "98101",
  "country": "USA",
  "phone": "555-1234",
  "email": "john@example.com"
}
```
5. Click "Execute"
6. You should see a 200 response with the order details

## Swagger Configuration

### Current Setup
- **Environment**: Development only
- **Version**: Swashbuckle.AspNetCore 6.5.0
- **Enabled**: Only when ASPNETCORE_ENVIRONMENT=Development

### Disabling Swagger
To disable Swagger (e.g., in production):
1. Set `ASPNETCORE_ENVIRONMENT=Production` in docker-compose.yml
2. Restart the containers

### Customizing Swagger
Swagger configuration is in each service's `Program.cs`:
```csharp
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new() { Title = "Catalog API", Version = "v1" });
});
```

## Benefits of Swagger

1. **Interactive Documentation**: Test APIs without writing code
2. **Schema Validation**: See exactly what data format is expected
3. **Quick Testing**: Verify endpoints work correctly
4. **Developer Onboarding**: New developers can explore APIs easily
5. **API Contract**: Clear documentation of what each endpoint does

## Troubleshooting

### Swagger Not Loading
- Verify the service is running: `docker ps`
- Check the environment is Development: `docker logs microservices-catalog-api-1`
- Ensure port is accessible: `curl http://localhost:5001/swagger/index.html`

### 404 Not Found
- Swagger is only enabled in Development mode
- Check ASPNETCORE_ENVIRONMENT in docker-compose.yml

### API Calls Failing
- Verify the backend service is healthy
- Check container logs for errors
- Ensure SQL Server is running and healthy

## Next Steps

- Test all endpoints using Swagger UI
- Verify the web application at http://localhost:5100 still works
- When ready, deploy to AWS using the AWS_DEPLOYMENT_GUIDE.md
