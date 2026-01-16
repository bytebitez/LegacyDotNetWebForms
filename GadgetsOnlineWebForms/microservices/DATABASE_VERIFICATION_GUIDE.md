# Database Verification Guide

## Database Structure

### Order Service Database

**Database Name:** `OrderDB`

**DbContext:** `OrderDbContext` (namespace: `GadgetsOnline.Order.API.Data`)

**Connection String (Docker):**
```
Server=sqlserver;Database=OrderDB;User Id=sa;Password=YourStrong@Passw0rd;TrustServerCertificate=True
```

**Connection String (Local):**
```
Data Source=(localdb)\MSSQLLocalDb;Initial Catalog=OrderDB;Integrated Security=SSPI
```

### Tables

#### 1. Orders Table
| Column | Type | Description |
|--------|------|-------------|
| OrderId | int (PK) | Primary key, auto-increment |
| OrderDate | datetime2 | Date and time of order |
| Username | nvarchar(max) | Customer username |
| FirstName | nvarchar(max) | Customer first name |
| LastName | nvarchar(max) | Customer last name |
| Address | nvarchar(max) | Shipping address |
| City | nvarchar(max) | City |
| State | nvarchar(max) | State |
| PostalCode | nvarchar(max) | Postal/ZIP code |
| Country | nvarchar(max) | Country |
| Phone | nvarchar(max) | Phone number |
| Email | nvarchar(max) | Email address |
| Total | decimal(18,2) | Order total amount |

#### 2. OrderDetails Table
| Column | Type | Description |
|--------|------|-------------|
| OrderDetailId | int (PK) | Primary key, auto-increment |
| OrderId | int (FK) | Foreign key to Orders table |
| ProductId | int | Product identifier |
| Quantity | int | Quantity ordered |
| UnitPrice | decimal(18,2) | Price per unit |

---

## Method 1: Using SQL Server Management Studio (SSMS)

### Connect to Docker SQL Server

1. **Open SSMS**
2. **Connection Details:**
   - Server name: `localhost,1433`
   - Authentication: SQL Server Authentication
   - Login: `sa`
   - Password: `YourStrong@Passw0rd`

3. **Query Orders:**
```sql
USE OrderDB;

-- View all orders
SELECT * FROM Orders ORDER BY OrderDate DESC;

-- View order details with product info
SELECT 
    o.OrderId,
    o.OrderDate,
    o.Username,
    o.FirstName + ' ' + o.LastName AS CustomerName,
    o.Total,
    od.ProductId,
    od.Quantity,
    od.UnitPrice,
    (od.Quantity * od.UnitPrice) AS LineTotal
FROM Orders o
INNER JOIN OrderDetails od ON o.OrderId = od.OrderId
ORDER BY o.OrderDate DESC, od.OrderDetailId;

-- Get order count
SELECT COUNT(*) AS TotalOrders FROM Orders;

-- Get latest order
SELECT TOP 1 * FROM Orders ORDER BY OrderDate DESC;
```

---

## Method 2: Using Azure Data Studio

### Connect to Docker SQL Server

1. **Open Azure Data Studio**
2. **New Connection:**
   - Connection type: Microsoft SQL Server
   - Server: `localhost,1433`
   - Authentication type: SQL Login
   - User name: `sa`
   - Password: `YourStrong@Passw0rd`
   - Database: `OrderDB`

3. **Run the same SQL queries as above**

---

## Method 3: Using PowerShell (sqlcmd)

### Connect via Docker Container

```powershell
# Connect to SQL Server container
docker exec -it microservices-sqlserver-1 /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "YourStrong@Passw0rd" -C

# Once connected, run:
USE OrderDB;
GO

SELECT * FROM Orders;
GO

SELECT * FROM OrderDetails;
GO

# Exit
EXIT
```

---

## Method 4: Using PowerShell Script

Create a PowerShell script to query the database:

```powershell
# verify-orders.ps1
$connectionString = "Server=localhost,1433;Database=OrderDB;User Id=sa;Password=YourStrong@Passw0rd;TrustServerCertificate=True"

$query = @"
SELECT 
    o.OrderId,
    o.OrderDate,
    o.Username,
    o.FirstName,
    o.LastName,
    o.Total,
    COUNT(od.OrderDetailId) AS ItemCount
FROM Orders o
LEFT JOIN OrderDetails od ON o.OrderId = od.OrderId
GROUP BY o.OrderId, o.OrderDate, o.Username, o.FirstName, o.LastName, o.Total
ORDER BY o.OrderDate DESC;
"@

try {
    $connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
    $connection.Open()
    
    $command = $connection.CreateCommand()
    $command.CommandText = $query
    
    $adapter = New-Object System.Data.SqlClient.SqlDataAdapter($command)
    $dataset = New-Object System.Data.DataSet
    $adapter.Fill($dataset)
    
    $dataset.Tables[0] | Format-Table -AutoSize
    
    $connection.Close()
}
catch {
    Write-Host "Error: $_" -ForegroundColor Red
}
```

---

## Method 5: Using API Endpoint

### Query via Order API

```powershell
# Get order by ID
$orderId = 1
curl.exe -s "http://localhost:5000/api/orders/$orderId" | ConvertFrom-Json | ConvertTo-Json -Depth 10

# Get orders by username
$username = "john.doe"
curl.exe -s "http://localhost:5000/api/orders/user/$username" | ConvertFrom-Json | ConvertTo-Json -Depth 10
```

---

## Testing: Create a Sample Order

### Step 1: Add Product to Cart
```powershell
$gateway = "http://localhost:5000"
$cartId = "test-user-123"

# Add product 1 to cart
curl.exe -X POST "$gateway/api/cart/$cartId/items" -H "Content-Type: application/json" -d "1"

# Add product 2 to cart
curl.exe -X POST "$gateway/api/cart/$cartId/items" -H "Content-Type: application/json" -d "2"

# Verify cart
curl.exe -s "$gateway/api/cart/$cartId"
```

### Step 2: Create Order
```powershell
$orderData = @{
    cartId = "test-user-123"
    username = "john.doe"
    firstName = "John"
    lastName = "Doe"
    address = "123 Main Street"
    city = "Seattle"
    state = "WA"
    postalCode = "98101"
    country = "USA"
    phone = "555-1234"
    email = "john.doe@example.com"
} | ConvertTo-Json

curl.exe -X POST "$gateway/api/orders" -H "Content-Type: application/json" -d $orderData
```

### Step 3: Verify in Database
```sql
-- Check the newly created order
SELECT TOP 1 * FROM Orders ORDER BY OrderDate DESC;

-- Check order details
SELECT * FROM OrderDetails WHERE OrderId = (SELECT MAX(OrderId) FROM Orders);
```

---

## Quick Verification Queries

### Check if tables exist
```sql
USE OrderDB;
SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE';
```

### Count records
```sql
SELECT 
    'Orders' AS TableName, COUNT(*) AS RecordCount FROM Orders
UNION ALL
SELECT 
    'OrderDetails' AS TableName, COUNT(*) AS RecordCount FROM OrderDetails;
```

### View latest order with details
```sql
DECLARE @LatestOrderId INT = (SELECT MAX(OrderId) FROM Orders);

SELECT 
    o.*,
    od.OrderDetailId,
    od.ProductId,
    od.Quantity,
    od.UnitPrice
FROM Orders o
LEFT JOIN OrderDetails od ON o.OrderId = od.OrderId
WHERE o.OrderId = @LatestOrderId;
```

---

## Other Databases

### Catalog Database
- **Database Name:** `CatalogDB`
- **Tables:** `Products`, `Categories`

### Cart Database
- **Database Name:** `CartDB`
- **Tables:** `CartItems`

All use the same connection credentials when running in Docker.
