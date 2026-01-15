# API Gateway Testing Script
Write-Host "=== Testing API Gateway Routing ===" -ForegroundColor Green
Write-Host ""

$gateway = "https://localhost:5000"

# Test 1: Get all products (Catalog API - Port 5011)
Write-Host "1. Testing GET /api/products (Catalog API)" -ForegroundColor Yellow
curl.exe -k -s "$gateway/api/products" -o $null -w "Status: %{http_code}\n"
Write-Host ""

# Test 2: Get product by ID
Write-Host "2. Testing GET /api/products/1 (Catalog API)" -ForegroundColor Yellow
curl.exe -k -s "$gateway/api/products/1" -o $null -w "Status: %{http_code}\n"
Write-Host ""

# Test 3: Get categories
Write-Host "3. Testing GET /api/categories (Catalog API)" -ForegroundColor Yellow
curl.exe -k -s "$gateway/api/categories" -o $null -w "Status: %{http_code}\n"
Write-Host ""

# Test 4: Get bestsellers
Write-Host "4. Testing GET /api/products/bestsellers (Catalog API)" -ForegroundColor Yellow
curl.exe -k -s "$gateway/api/products/bestsellers" -o $null -w "Status: %{http_code}\n"
Write-Host ""

# Test 5: Get cart (Cart API - Port 5012)
Write-Host "5. Testing GET /api/cart/test-cart (Cart API)" -ForegroundColor Yellow
curl.exe -k -s "$gateway/api/cart/test-cart" -o $null -w "Status: %{http_code}\n"
Write-Host ""

# Test 6: Add to cart (Cart API)
Write-Host "6. Testing POST /api/cart/test-cart/items?productId=1 (Cart API)" -ForegroundColor Yellow
curl.exe -k -s -X POST "$gateway/api/cart/test-cart/items?productId=1" -o $null -w "Status: %{http_code}\n"
Write-Host ""

Write-Host "=== All Routes Tested ===" -ForegroundColor Green
Write-Host ""
Write-Host "Expected Status Codes:" -ForegroundColor Cyan
Write-Host "  200 = Success"
Write-Host "  404 = Not Found"
Write-Host "  500 = Server Error"
