# How to Connect to Docker SQL Server

## The Issue

You are currently connected to **LocalDB** (`(localdb)\MSSQLLocalDb`), but the microservices are using **Docker SQL Server** (`localhost,1433`).

Order ID 2005 exists in the Docker SQL Server, not in LocalDB.

---

## Connection Details for Docker SQL Server

### For SQL Server Management Studio (SSMS)

1. **Open SSMS**
2. Click **Connect** → **Database Engine**
3. Enter these details:

```
Server name:        localhost,1433
                    (use comma, not colon!)

Authentication:     SQL Server Authentication

Login:              sa

Password:           YourStrong@Passw0rd

Database:           OrderDB
```

4. Click **Connect**

---

### For Azure Data Studio

1. **Open Azure Data Studio**
2. Click **New Connection**
3. Enter these details:

```
Connection type:    Microsoft SQL Server

Server:             localhost,1433

Authentication:     SQL Login

User name:          sa

Password:           YourStrong@Passw0rd

Database:           OrderDB

Trust server certificate: Yes (checked)
```

4. Click **Connect**

---

## Verify the Connection

Once connected, run this query:

```sql
-- Check current database
SELECT DB_NAME() AS CurrentDatabase;

-- List all databases
SELECT name FROM sys.databases;

-- View orders
USE OrderDB;
SELECT TOP 10 
    OrderId, 
    OrderDate, 
    Username, 
    FirstName + ' ' + LastName AS CustomerName,
    City,
    State,
    Total
FROM Orders 
ORDER BY OrderDate DESC;

-- Find Order 2005
SELECT * FROM Orders WHERE OrderId = 2005;
SELECT * FROM OrderDetails WHERE OrderId = 2005;
```

---

## Why Two Different Databases?

### LocalDB (Your Current Connection)
- **Server:** `(localdb)\MSSQLLocalDb`
- **Purpose:** Local development database
- **Used by:** Your original monolithic application
- **Location:** Local machine

### Docker SQL Server (Microservices)
- **Server:** `localhost,1433`
- **Purpose:** Containerized database for microservices
- **Used by:** All three microservices (Catalog, Cart, Order)
- **Location:** Docker container

---

## All Microservices Databases in Docker

When connected to `localhost,1433`, you'll see these databases:

1. **CatalogDB** - Products and Categories
2. **CartDB** - Shopping cart items
3. **OrderDB** - Orders and order details (where Order 2005 is stored)

---

## Quick Test

After connecting to Docker SQL Server, run:

```sql
USE OrderDB;

-- Should return Order 2005
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
WHERE o.OrderId = 2005
GROUP BY o.OrderId, o.OrderDate, o.Username, o.FirstName, o.LastName, o.Total;
```

**Expected Result:**
- OrderId: 2005
- Username: testuser
- FirstName: Test
- LastName: User
- Total: 1698.00
- ItemCount: 2

---

## Troubleshooting

### "Cannot connect to localhost,1433"

**Check if Docker SQL Server is running:**
```powershell
docker ps | findstr sqlserver
```

Should show: `microservices-sqlserver-1` with status "Up"

**If not running, start services:**
```powershell
cd GadgetsOnlineWebForms/microservices
docker-compose up -d
```

### "Login failed for user 'sa'"

- Double-check password: `YourStrong@Passw0rd`
- Make sure you're using **SQL Server Authentication**, not Windows Authentication

### "Database 'OrderDB' does not exist"

The database is created automatically when the Order API starts. Make sure:
1. Docker containers are running
2. Order API has started successfully
3. Wait a few seconds for database initialization

---

## Summary

✅ **Correct Connection:** `localhost,1433` with user `sa`  
❌ **Wrong Connection:** `(localdb)\MSSQLLocalDb` (your current connection)

Switch to the Docker SQL Server connection to see Order 2005!
