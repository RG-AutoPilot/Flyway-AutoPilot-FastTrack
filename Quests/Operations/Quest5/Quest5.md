**RUN THE SQL SCRIPT FIRST TO CREATE THE NEEDED QUEST ITEMS**

# Operations Quest 5: Computed Columns and Performance Indexes

**Difficulty:** ⭐⭐⭐ Intermediate-Advanced  
**Time:** 30-40 minutes  
**Prerequisites:** Completed Operations Quest 4

## Learning Objectives
By completing this quest, you will learn:
- Creating computed columns for calculated values
- Indexing computed columns for performance
- Understanding persisted vs non-persisted computed columns
- Using computed columns to optimize queries
- Best practices for computed column design

## Scenario
Your analytics team is constantly running reports that calculate flight duration from `DepartureTime` and `ArrivalTime` in the `Inventory.Flight` table. The calculation (`DATEDIFF(MINUTE, DepartureTime, ArrivalTime)`) appears in dozens of queries and reports, causing:
- Repeated calculation overhead
- Slow aggregation queries
- Inconsistent calculation logic across queries
- Difficulty indexing calculated values

Your task is to add a computed column for flight duration and create an index to optimize these common queries.

## Your Mission
Add a computed column `FlightDurationMinutes` to the `Inventory.Flight` table and create an optimized index on it.

## Objective
1. Add a computed column to calculate flight duration in minutes
2. Make the computed column persisted for better performance
3. Create an index on the computed column
4. Test query performance improvements
5. Update existing queries to use the new column

## What are Computed Columns?

**Computed Column**: A virtual column whose value is calculated from other columns.

**Types:**
- **Non-Persisted**: Calculated on-the-fly when queried (default)
- **Persisted**: Stored physically, calculated once when row is inserted/updated

**Benefits:**
- Consistent calculations across all queries
- Can be indexed (if persisted or deterministic)
- Simplifies query logic
- Improves performance for repeated calculations

## Steps

### Step 1: Review Current Query Pattern

```sql
-- Current approach (inefficient - calculates every time)
SELECT 
    FlightID,
    FlightNumber,
    DATEDIFF(MINUTE, DepartureTime, ArrivalTime) AS FlightDuration,
    DepartureTime,
    ArrivalTime
FROM Inventory.Flight
WHERE DATEDIFF(MINUTE, DepartureTime, ArrivalTime) > 180  -- Long flights
ORDER BY DATEDIFF(MINUTE, DepartureTime, ArrivalTime) DESC;

-- Problems:
-- 1. Calculation runs for every row
-- 2. Can't index the calculated value
-- 3. Repeated code across queries
```

### Step 2: Add Computed Column

```sql
-- Add computed column (persisted for indexing)
ALTER TABLE Inventory.Flight
ADD FlightDurationMinutes AS 
    DATEDIFF(MINUTE, DepartureTime, ArrivalTime) 
PERSISTED;
```

**Why PERSISTED?**
- Allows indexing (required for non-deterministic functions)
- Faster queries (no repeated calculation)
- Slightly more storage space
- Slower inserts/updates (calculation happens then)

### Step 3: Create Index on Computed Column

```sql
-- Create index for range queries and sorting
CREATE NONCLUSTERED INDEX IX_Flight_FlightDurationMinutes
ON Inventory.Flight(FlightDurationMinutes)
INCLUDE (FlightID, FlightNumber, DepartureTime, ArrivalTime);
```

**Index Design:**
- **Key column**: FlightDurationMinutes (for filtering and sorting)
- **INCLUDE columns**: Commonly selected columns (covering index)

### Step 4: Verify the Computed Column

```sql
-- Check column definition
SELECT 
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE,
    COLUMN_DEFAULT
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'Flight' 
    AND TABLE_SCHEMA = 'Inventory'
    AND COLUMN_NAME = 'FlightDurationMinutes';

-- View column properties including computed definition
EXEC sp_help 'Inventory.Flight';
```

### Step 5: Test Query Performance

```sql
-- Enable execution plan and statistics
SET STATISTICS TIME ON;
SET STATISTICS IO ON;

-- NEW query using computed column
SELECT 
    FlightID,
    FlightNumber,
    FlightDurationMinutes,  -- No calculation needed!
    DepartureTime,
    ArrivalTime
FROM Inventory.Flight
WHERE FlightDurationMinutes > 180
ORDER BY FlightDurationMinutes DESC;

-- Check execution plan - should use the index

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
```

### Step 6: Common Queries to Optimize

```sql
-- Example 1: Average flight duration by route
SELECT 
    DepartureCity,
    ArrivalCity,
    AVG(FlightDurationMinutes) AS AvgDurationMinutes,
    COUNT(*) AS FlightCount
FROM Inventory.Flight
GROUP BY DepartureCity, ArrivalCity
ORDER BY AvgDurationMinutes DESC;

-- Example 2: Find flights within duration range
SELECT FlightID, FlightNumber, FlightDurationMinutes
FROM Inventory.Flight
WHERE FlightDurationMinutes BETWEEN 90 AND 120;  -- 1.5 to 2 hours

-- Example 3: Longest flights this month
SELECT TOP 10
    FlightNumber,
    DepartureCity,
    ArrivalCity,
    FlightDurationMinutes,
    DepartureTime
FROM Inventory.Flight
WHERE DepartureTime >= DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0)
ORDER BY FlightDurationMinutes DESC;
```

### Step 7: Create Flyway Migration

Create versioned migration:
```
V014__Add_flight_duration_computed_column.sql
```

Include:
- ALTER TABLE to add computed column
- CREATE INDEX statement
- Comments explaining the optimization

## Hints
- **PERSISTED Required**: For indexing computed columns
- **Deterministic Functions**: Only deterministic functions can be persisted
- **Index Design**: Use INCLUDE for covering indexes
- **Testing**: Compare execution plans before/after
- **Documentation**: Comment why the column exists in schema

## Key Concepts Learned
- **Computed Columns**: Virtual columns with calculated values
- **Persisted Storage**: Trading storage for performance
- **Covering Indexes**: Include frequently selected columns
- **Query Optimization**: Using indexes effectively
- **Schema Design**: Adding derived columns strategically

## Performance Comparison

### Before (No Computed Column):
```sql
-- Table Scan + Calculation
SELECT * FROM Inventory.Flight
WHERE DATEDIFF(MINUTE, DepartureTime, ArrivalTime) > 180;

-- Execution: 
-- - Table Scan (slow)
-- - Calculation for every row
-- - CPU time: ~500ms
-- - Logical reads: ~5,000
```

### After (With Computed Column & Index):
```sql
-- Index Seek
SELECT * FROM Inventory.Flight
WHERE FlightDurationMinutes > 180;

-- Execution:
-- - Index Seek (fast)
-- - No calculation needed
-- - CPU time: ~50ms
-- - Logical reads: ~200
-- Performance improvement: ~10x!
```

## Common Pitfalls to Avoid
❌ **Non-deterministic functions without PERSISTED**: Can't be indexed  
✅ **Solution**: Use PERSISTED for non-deterministic functions

❌ **Forgetting the index**: Computed column alone doesn't help much  
✅ **Solution**: Create appropriate indexes on computed columns

❌ **Computed columns referencing computed columns**: Complex dependencies  
✅ **Solution**: Keep computed column definitions simple

❌ **Using in frequently updated tables**: Slows down updates  
✅ **Solution**: Only use for read-heavy tables

## Success Criteria
✅ Computed column `FlightDurationMinutes` added to `Inventory.Flight`  
✅ Column is PERSISTED  
✅ Index `IX_Flight_FlightDurationMinutes` created  
✅ Test queries run faster (verify with execution plans)  
✅ Queries use the index (check execution plan)  
✅ Migration committed to source control

## Troubleshooting
- **"Cannot create index"**: Ensure column is PERSISTED
- **Index not used**: Check query predicates match index key
- **Null values**: Handle cases where DepartureTime or ArrivalTime are NULL
- **Incorrect calculations**: Verify DATEDIFF function and units

## Advanced Computed Column Examples

```sql
-- Example 1: Full name computed column
ALTER TABLE Customers.Customer
ADD FullName AS (FirstName + ' ' + LastName) PERSISTED;

-- Example 2: Age from birthdate
ALTER TABLE Customers.Customer
ADD Age AS (DATEDIFF(YEAR, BirthDate, GETDATE())) PERSISTED;

-- Example 3: Tax amount from price
ALTER TABLE Sales.Orders
ADD TaxAmount AS (TotalPrice * 0.08) PERSISTED;

-- Example 4: Status from dates
ALTER TABLE Sales.Campaigns
ADD Status AS (
    CASE 
        WHEN GETDATE() < StartDate THEN 'Upcoming'
        WHEN GETDATE() BETWEEN StartDate AND EndDate THEN 'Active'
        ELSE 'Completed'
    END
) PERSISTED;
```

## Real-World Applications
- **E-commerce**: Total price with tax
- **HR Systems**: Employee age from birthdate
- **Logistics**: Delivery time from timestamps
- **Financial**: Interest calculations, YTD totals
- **Healthcare**: BMI from height/weight

## Advanced Challenge (Optional)
1. Add a computed column for `DistancePerMinute` (requires distance column)
2. Create a filtered index for only long-haul flights (> 180 minutes)
3. Add a computed column showing timezone differences
4. Create statistics on the computed column for better query plans

## Next Steps
Great work on performance optimization! Move on to **Operations Quest 6** to learn about cascading deletes and advanced constraints!
