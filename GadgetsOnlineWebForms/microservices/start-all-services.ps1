# PowerShell script to start all microservices

Write-Host "Starting GadgetsOnline Microservices..." -ForegroundColor Green

# Start Catalog Service
Write-Host "`nStarting Catalog Service on port 5001..." -ForegroundColor Cyan
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd src\GadgetsOnline.Catalog.API; dotnet run"

Start-Sleep -Seconds 3

# Start Cart Service
Write-Host "Starting Cart Service on port 5002..." -ForegroundColor Cyan
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd src\GadgetsOnline.Cart.API; dotnet run"

Start-Sleep -Seconds 3

# Start Order Service
Write-Host "Starting Order Service on port 5003..." -ForegroundColor Cyan
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd src\GadgetsOnline.Order.API; dotnet run"

Start-Sleep -Seconds 3

# Start API Gateway
Write-Host "Starting API Gateway on port 5000..." -ForegroundColor Cyan
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd src\GadgetsOnline.ApiGateway; dotnet run"

Start-Sleep -Seconds 3

# Start Web Frontend
Write-Host "Starting Web Frontend on port 5100..." -ForegroundColor Cyan
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd src\GadgetsOnline.Web; dotnet run"

Write-Host "`nAll services are starting..." -ForegroundColor Green
Write-Host "Web Frontend: https://localhost:5100" -ForegroundColor Yellow
Write-Host "API Gateway: https://localhost:5000" -ForegroundColor Yellow
Write-Host "Catalog API: https://localhost:5001/swagger" -ForegroundColor Yellow
Write-Host "Cart API: https://localhost:5002/swagger" -ForegroundColor Yellow
Write-Host "Order API: https://localhost:5003/swagger" -ForegroundColor Yellow
Write-Host "`nPress any key to exit..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
