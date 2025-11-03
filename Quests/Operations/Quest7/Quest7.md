**RUN THE SQL SCRIPT FIRST TO CREATE THE NEEDED QUEST ITEMS**

# Operations Quest 7: Unique Constraints and Data Integrity

**Difficulty:** ⭐⭐⭐ Intermediate  
**Time:** 25-30 minutes  
**Prerequisites:** Completed Operations Quest 6

## Learning Objectives
By completing this quest, you will learn:
- Creating unique constraints vs unique indexes
- Multi-column unique constraints
- Enforcing business rules at the database level
- Handling constraint violations
- Cleaning existing duplicate data

## Scenario
The `Inventory.FlightRoute` table stores all possible flight routes between cities. However, there's a problem: duplicate routes can be entered! For example:
- New York → Los Angeles
- New York → Los Angeles (duplicate!)

This causes issues:
- Confused route planning
- Duplicate data entry
- Reporting inaccuracies
- Pricing inconsistencies

The operations team wants to ensure that each route combination (DepartureCity + ArrivalCity) is unique.

## Your Mission
Add a unique constraint to prevent duplicate routes while handling any existing duplicates.

## Objective
1. Identify any existing duplicate routes
2. Clean up duplicate data
3. Add a unique constraint on the combination of DepartureCity and ArrivalCity
4. Test the constraint
5. Document the business rule

## Understanding Unique Constraints

**Unique Constraint**: Ensures all values in a column (or combination of columns) are unique.

**Key Differences:**
| Feature | Unique Constraint | Unique Index |
|---------|------------------|--------------|
| Purpose | Enforce uniqueness | Improve performance + uniqueness |
| NULL handling | Allows multiple NULLs | Depends on configuration |
| Creation | ALTER TABLE | CREATE INDEX |
| Naming | System or user-defined | User-defined |

**When to Use:**
- ✅ Enforce business rules (email must be unique)
- ✅ Natural keys (SSN, license number, SKU)
- ✅ Multi-column uniqueness (route combinations)
- ✅ Prevent data entry errors

## Steps

### Step 1: Identify Existing Duplicates

```sql
-- Find duplicate routes
SELECT 
    DepartureCity,
    ArrivalCity,
    COUNT(*) AS DuplicateCount
FROM Inventory.FlightRoute
GROUP BY DepartureCity, ArrivalCity
HAVING COUNT(*) > 1
ORDER BY DuplicateCount DESC;

-- Get detailed view of duplicates
WITH DuplicateRoutes AS (
    SELECT 
        RouteID,
        DepartureCity,
        ArrivalCity,
        ROW_NUMBER() OVER (
            PARTITION BY DepartureCity, ArrivalCity 
            ORDER BY RouteID
        ) AS RowNum
    FROM Inventory.FlightRoute
)
SELECT *
FROM DuplicateRoutes
WHERE RowNum > 1;
```

### Step 2: Clean Up Duplicates

**Option A: Keep the oldest route (lowest RouteID)**
```sql
-- Delete duplicates, keep first occurrence
WITH DuplicateRoutes AS (
    SELECT 
        RouteID,
        ROW_NUMBER() OVER (
            PARTITION BY DepartureCity, ArrivalCity 
            ORDER BY RouteID
        ) AS RowNum
    FROM Inventory.FlightRoute
)
DELETE FROM DuplicateRoutes
WHERE RowNum > 1;
```

**Option B: Merge data before deleting**
```sql
-- If routes have additional data (distance, etc.), merge it first
UPDATE fr1
SET fr1.Distance = CASE 
    WHEN fr1.Distance IS NULL THEN fr2.Distance 
    ELSE fr1.Distance 
END
FROM Inventory.FlightRoute fr1
INNER JOIN Inventory.FlightRoute fr2 
    ON fr1.DepartureCity = fr2.DepartureCity
    AND fr1.ArrivalCity = fr2.ArrivalCity
    AND fr1.RouteID < fr2.RouteID;

-- Then delete duplicates
WITH DuplicateRoutes AS (
    SELECT 
        RouteID,
        ROW_NUMBER() OVER (
            PARTITION BY DepartureCity, ArrivalCity 
            ORDER BY RouteID
        ) AS RowNum
    FROM Inventory.FlightRoute
)
DELETE FROM DuplicateRoutes
WHERE RowNum > 1;
```

### Step 3: Verify Cleanup

```sql
-- Should return 0 rows now
SELECT 
    DepartureCity,
    ArrivalCity,
    COUNT(*) AS Count
FROM Inventory.FlightRoute
GROUP BY DepartureCity, ArrivalCity
HAVING COUNT(*) > 1;
```

### Step 4: Add Unique Constraint

```sql
-- Add unique constraint on the combination
ALTER TABLE Inventory.FlightRoute
ADD CONSTRAINT UQ_FlightRoute_Cities
UNIQUE (DepartureCity, ArrivalCity);
```

Alternative using unique index:
```sql
-- Or create a unique index (slightly different approach)
CREATE UNIQUE NONCLUSTERED INDEX UQ_FlightRoute_Cities
ON Inventory.FlightRoute(DepartureCity, ArrivalCity);
```

### Step 5: Test the Constraint

```sql
-- This should succeed
INSERT INTO Inventory.FlightRoute (RouteID, DepartureCity, ArrivalCity)
VALUES (999991, 'Seattle', 'Portland');

-- This should FAIL with unique constraint violation
INSERT INTO Inventory.FlightRoute (RouteID, DepartureCity, ArrivalCity)
VALUES (999992, 'Seattle', 'Portland');
-- Error: "Violation of UNIQUE KEY constraint 'UQ_FlightRoute_Cities'"

-- Cleanup test data
DELETE FROM Inventory.FlightRoute WHERE RouteID = 999991;
```

### Step 6: Handle Constraint Violations in Application

```sql
-- Application code should handle this gracefully
-- Example: Try to insert, catch error, inform user

-- Or use MERGE for upsert behavior
MERGE INTO Inventory.FlightRoute AS target
USING (SELECT 'Seattle' AS DepartureCity, 'Portland' AS ArrivalCity) AS source
ON target.DepartureCity = source.DepartureCity 
    AND target.ArrivalCity = source.ArrivalCity
WHEN NOT MATCHED THEN
    INSERT (DepartureCity, ArrivalCity)
    VALUES (source.DepartureCity, source.ArrivalCity);
```

### Step 7: Create Flyway Migration

Create versioned migration:
```
V016__Add_unique_constraint_to_flight_routes.sql
```

Migration content:
```sql
-- Clean up any existing duplicates
WITH DuplicateRoutes AS (
    SELECT 
        RouteID,
        ROW_NUMBER() OVER (
            PARTITION BY DepartureCity, ArrivalCity 
            ORDER BY RouteID
        ) AS RowNum
    FROM Inventory.FlightRoute
)
DELETE FROM DuplicateRoutes
WHERE RowNum > 1;

-- Add unique constraint
ALTER TABLE Inventory.FlightRoute
ADD CONSTRAINT UQ_FlightRoute_Cities
UNIQUE (DepartureCity, ArrivalCity);
```

## Hints
- **Check First**: Always check for duplicates before adding constraint
- **Clean Up**: Remove duplicates before constraint creation
- **Test**: Try inserting duplicates to verify constraint works
- **Application Logic**: Update app to handle constraint violations
- **Documentation**: Document the business rule

## Key Concepts Learned
- **Unique Constraints**: Enforce uniqueness across columns
- **Multi-Column Constraints**: Uniqueness on column combinations
- **Data Cleansing**: Removing duplicates before adding constraints
- **Constraint Violations**: Handling errors gracefully
- **Business Rule Enforcement**: Database-level data integrity

## Common Unique Constraint Patterns

```sql
-- Single column unique
ALTER TABLE Users
ADD CONSTRAINT UQ_Users_Email UNIQUE (Email);

-- Multi-column unique
ALTER TABLE Reservations
ADD CONSTRAINT UQ_Reservation_FlightSeat 
UNIQUE (FlightID, SeatNumber);

-- Conditional unique (using filtered index in SQL Server)
CREATE UNIQUE INDEX UQ_ActiveUsers_Email
ON Users(Email)
WHERE IsActive = 1;  -- Only enforce for active users

-- Case-insensitive unique (use computed column)
ALTER TABLE Users
ADD EmailLower AS LOWER(Email) PERSISTED;

ALTER TABLE Users
ADD CONSTRAINT UQ_Users_EmailLower UNIQUE (EmailLower);
```

## Common Pitfalls to Avoid
❌ **Adding constraint without checking for duplicates**: Fails!  
✅ **Solution**: Query for duplicates first, clean them up

❌ **NULL handling misunderstanding**: Multiple NULLs are allowed  
✅ **Solution**: Use NOT NULL if needed

❌ **Wrong column combination**: Doesn't enforce intended rule  
✅ **Solution**: Carefully think through the business rule

❌ **No error handling in app**: App crashes on constraint violation  
✅ **Solution**: Add try-catch and user-friendly messages

## Success Criteria
✅ Existing duplicate routes identified and removed  
✅ Unique constraint `UQ_FlightRoute_Cities` added  
✅ Test confirms duplicate inserts are blocked  
✅ No duplicate routes exist in the table  
✅ Migration script created and tested  
✅ Documentation explains the business rule  
✅ Migration committed to source control

## Troubleshooting
- **"Constraint failed to create"**: Check for existing duplicates
- **NULLs causing issues**: Consider adding NOT NULL constraints
- **Performance problems**: Unique constraints create indexes automatically
- **Application errors**: Update app code to handle violations

## Real-World Applications
- **User Management**: Unique email addresses
- **E-commerce**: Unique SKU/product codes
- **Inventory**: Unique serial numbers
- **Booking Systems**: Unique seat assignments per flight
- **Financial**: Unique transaction IDs

## Advanced Patterns

### Soft Unique Constraints:
```sql
-- Only enforce unique for non-deleted records
CREATE UNIQUE INDEX UQ_Products_SKU
ON Products(SKU)
WHERE IsDeleted = 0;
```

### Time-Based Unique Constraints:
```sql
-- Unique booking per room per day
ALTER TABLE Bookings
ADD CONSTRAINT UQ_Booking_RoomDate
UNIQUE (RoomID, BookingDate);
```

### Multi-Tenant Unique Constraints:
```sql
-- Unique within tenant
ALTER TABLE Products
ADD CONSTRAINT UQ_Products_SKU_TenantID
UNIQUE (TenantID, SKU);
```

## Advanced Challenge (Optional)
1. Add a unique constraint that allows NULLs but prevents duplicate non-NULL values
2. Create a filtered unique index for only active routes
3. Implement a trigger to log constraint violations for monitoring
4. Add a unique constraint across multiple tables using a computed column

## Congratulations!
You've completed all the **Operations (Intermediate)** quests! You now know:
- Schema normalization and refactoring
- Large table splitting and optimization
- Managing pending changes
- Table partitioning
- Computed columns and indexes
- Cascading deletes
- Unique constraints

Ready for expert-level challenges? Move on to the **Validation (Advanced)** quests!
