Write-Host "Testing Microservices..." -ForegroundColor Cyan
Write-Host ""

# Test Catalog API directly
Write-Host "1. Testing Catalog API (HTTP)..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:5011/api/products" -UseBasicParsing
    Write-Host "   ✓ Catalog API: OK (Status: $($response.StatusCode))" -ForegroundColor Green
    $products = $response.Content | ConvertFrom-Json
    Write-Host "   ✓ Products found: $($products.Count)" -ForegroundColor Green
} catch {
    Write-Host "   ✗ Catalog API: FAILED - $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Test API Gateway
Write-Host "2. Testing API Gateway (HTTP)..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:5010/api/products" -UseBasicParsing
    Write-Host "   ✓ API Gateway: OK (Status: $($response.StatusCode))" -ForegroundColor Green
    $products = $response.Content | ConvertFrom-Json
    Write-Host "   ✓ Products through Gateway: $($products.Count)" -ForegroundColor Green
} catch {
    Write-Host "   ✗ API Gateway: FAILED - $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Test Categories
Write-Host "3. Testing Categories..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:5010/api/categories" -UseBasicParsing
    Write-Host "   ✓ Categories API: OK (Status: $($response.StatusCode))" -ForegroundColor Green
    $categories = $response.Content | ConvertFrom-Json
    Write-Host "   ✓ Categories found: $($categories.Count)" -ForegroundColor Green
} catch {
    Write-Host "   ✗ Categories API: FAILED - $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "Testing complete!" -ForegroundColor Cyan
Write-Host ""
Write-Host "Web Frontend is running at: https://localhost:5100" -ForegroundColor Green
Write-Host "Open this URL in your browser to see the application." -ForegroundColor Green
