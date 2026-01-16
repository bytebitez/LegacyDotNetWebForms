# Test Async Messaging with RabbitMQ
Write-Host "=== Testing Async Messaging Flow ===" -ForegroundColor Cyan

# Step 1: Add items to cart
Write-Host "`n1. Adding items to cart (username: testuser)..." -ForegroundColor Yellow
$addItem1 = Invoke-RestMethod -Uri "http://localhost:5000/api/cart/testuser/items" `
    -Method POST `
    -ContentType "application/json" `
    -Body '1'
Write-Host "Added Product 1 to cart" -ForegroundColor Green

$addItem2 = Invoke-RestMethod -Uri "http://localhost:5000/api/cart/testuser/items" `
    -Method POST `
    -ContentType "application/json" `
    -Body '2'
Write-Host "Added Product 2 to cart" -ForegroundColor Green

# Step 2: Check cart before order
Write-Host "`n2. Checking cart contents..." -ForegroundColor Yellow
$cartBefore = Invoke-RestMethod -Uri "http://localhost:5000/api/cart/testuser" -Method GET
Write-Host "Cart has $($cartBefore.items.Count) items" -ForegroundColor Green
$cartBefore.items | ForEach-Object { Write-Host "  - Product $($_.productId): $($_.productName) x $($_.quantity)" }

# Step 3: Create order
Write-Host "`n3. Creating order..." -ForegroundColor Yellow
$orderData = @{
    username = "testuser"
    items = @(
        @{ productId = 1; quantity = 1; price = 999.99 },
        @{ productId = 2; quantity = 1; price = 699.99 }
    )
} | ConvertTo-Json

$order = Invoke-RestMethod -Uri "http://localhost:5000/api/orders" `
    -Method POST `
    -ContentType "application/json" `
    -Body $orderData
Write-Host "Order created: ID = $($order.orderId), Total = `$$($order.total)" -ForegroundColor Green

# Step 4: Wait for async message processing
Write-Host "`n4. Waiting for RabbitMQ to process cart clearing (3 seconds)..." -ForegroundColor Yellow
Start-Sleep -Seconds 3

# Step 5: Check cart after order (should be empty)
Write-Host "`n5. Checking cart after order..." -ForegroundColor Yellow
try {
    $cartAfter = Invoke-RestMethod -Uri "http://localhost:5000/api/cart/testuser" -Method GET
    if ($cartAfter.items.Count -eq 0) {
        Write-Host "SUCCESS! Cart was cleared automatically via RabbitMQ message!" -ForegroundColor Green
    } else {
        Write-Host "Cart still has $($cartAfter.items.Count) items" -ForegroundColor Red
    }
} catch {
    Write-Host "Cart is empty (404 expected)" -ForegroundColor Green
}

Write-Host "`n=== Test Complete ===" -ForegroundColor Cyan
Write-Host "`nCheck RabbitMQ Management UI: http://localhost:15672" -ForegroundColor Yellow
Write-Host "Username: guest, Password: guest" -ForegroundColor Yellow
