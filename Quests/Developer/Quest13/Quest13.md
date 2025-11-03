**RUN THE SQL SCRIPT FIRST TO CREATE THE NEEDED QUEST ITEMS**

# Developer Quest 13: Check Constraints and Data Validation

**Difficulty:** Advanced  
**Time:** 30-40 minutes  
**Prerequisites:** Completed Developer Quest 12

## Learning Objectives
By completing this quest, you will learn:
- Creating check constraints for data validation
- Complex constraint expressions
- Business rule enforcement at database level
- Constraint naming conventions
- Performance implications of constraints

## Scenario
The `Inventory.Flight` table has a critical data quality issue: some flights have been entered with zero or negative available seats! This causes:
- Booking system errors
- Revenue calculation problems
- Confused customers seeing "0 seats available"
- Invalid business reports

Additionally, the business team wants to ensure:
- Available seats cannot be negative
- Available seats should not exceed aircraft capacity (500 seats max)
- Departure time must be before arrival time

Your task is to add check constraints to enforce these business rules at the database level.

## Your Mission
Add multiple check constraints to the `Inventory.Flight` table to validate data integrity.

## Objective
1. Add constraint: AvailableSeats must be greater than 0
2. Add constraint: AvailableSeats cannot exceed 500
3. Add constraint: DepartureTime must be before ArrivalTime
4. Clean existing invalid data before adding constraints
5. Test all constraints thoroughly

## Understanding Check Constraints

**Check Constraint**: A rule that limits the values that can be stored in a column.

**Benefits:**
- ✅ Enforces business rules automatically
- ✅ Prevents invalid data at insert/update time
- ✅ Documents business rules in schema
- ✅ Centralized validation (not just in app code)

**Limitations:**
- ❌ Cannot reference other tables (use triggers for that)
- ❌ Cannot use subqueries
- ❌ Can impact insert/update performance slightly

## Steps

### Step 1: Analyze Current Data Quality

```sql
-- Find flights with invalid seat counts
SELECT 
    FlightID,
    FlightNumber,
    AvailableSeats,
    CASE 
        WHEN AvailableSeats < 0 THEN 'Negative seats'
        WHEN AvailableSeats = 0 THEN 'Zero seats'
        WHEN AvailableSeats > 500 THEN 'Exceeds capacity'
        ELSE 'Valid'
    END AS Issue
FROM Inventory.Flight
WHERE AvailableSeats <= 0 OR AvailableSeats > 500;

-- Find flights with invalid time logic
SELECT 
    FlightID,
    FlightNumber,
    DepartureTime,
    ArrivalTime,
    DATEDIFF(MINUTE, DepartureTime, ArrivalTime) AS DurationMinutes
FROM Inventory.Flight
WHERE DepartureTime >= ArrivalTime;
```

### Step 2: Clean Invalid Data

```sql
-- Fix negative or zero seats (set to a reasonable default)
UPDATE Inventory.Flight
SET AvailableSeats = 100  -- Reasonable default
WHERE AvailableSeats <= 0;

-- Fix seats exceeding capacity
UPDATE Inventory.Flight
SET AvailableSeats = 500  -- Max capacity
WHERE AvailableSeats > 500;

-- Fix invalid times (this is trickier - might need case-by-case review)
-- Option 1: Add 1 hour to departure if times are wrong
UPDATE Inventory.Flight
SET DepartureTime = DATEADD(HOUR, -1, ArrivalTime)
WHERE DepartureTime >= ArrivalTime;

-- Verify cleanup
SELECT COUNT(*) AS InvalidFlights
FROM Inventory.Flight
WHERE AvailableSeats <= 0 
    OR AvailableSeats > 500
    OR DepartureTime >= ArrivalTime;
-- Should return 0
```

### Step 3: Add Check Constraints

```sql
-- Constraint 1: Positive seats
ALTER TABLE Inventory.Flight
ADD CONSTRAINT CHK_Flight_AvailableSeats_Positive
CHECK (AvailableSeats > 0);

-- Constraint 2: Maximum capacity
ALTER TABLE Inventory.Flight
ADD CONSTRAINT CHK_Flight_AvailableSeats_MaxCapacity
CHECK (AvailableSeats <= 500);

-- Constraint 3: Valid time sequence
ALTER TABLE Inventory.Flight
ADD CONSTRAINT CHK_Flight_DepartureBeforeArrival
CHECK (DepartureTime < ArrivalTime);

-- Optional: Combine into one constraint
-- ALTER TABLE Inventory.Flight
-- ADD CONSTRAINT CHK_Flight_AvailableSeats
-- CHECK (AvailableSeats > 0 AND AvailableSeats <= 500);
```

### Step 4: Test the Constraints

```sql
-- Test 1: Try to insert negative seats (should FAIL)
INSERT INTO Inventory.Flight (FlightID, FlightNumber, AvailableSeats, DepartureTime, ArrivalTime)
VALUES (999991, 'TEST001', -5, GETDATE(), DATEADD(HOUR, 2, GETDATE()));
-- Error: CHECK constraint "CHK_Flight_AvailableSeats_Positive"

-- Test 2: Try to insert zero seats (should FAIL)
INSERT INTO Inventory.Flight (FlightID, FlightNumber, AvailableSeats, DepartureTime, ArrivalTime)
VALUES (999992, 'TEST002', 0, GETDATE(), DATEADD(HOUR, 2, GETDATE()));
-- Error: CHECK constraint "CHK_Flight_AvailableSeats_Positive"

-- Test 3: Try to insert excessive seats (should FAIL)
INSERT INTO Inventory.Flight (FlightID, FlightNumber, AvailableSeats, DepartureTime, ArrivalTime)
VALUES (999993, 'TEST003', 501, GETDATE(), DATEADD(HOUR, 2, GETDATE()));
-- Error: CHECK constraint "CHK_Flight_AvailableSeats_MaxCapacity"

-- Test 4: Try to insert invalid times (should FAIL)
INSERT INTO Inventory.Flight (FlightID, FlightNumber, AvailableSeats, DepartureTime, ArrivalTime)
VALUES (999994, 'TEST004', 100, GETDATE(), DATEADD(HOUR, -2, GETDATE()));
-- Error: CHECK constraint "CHK_Flight_DepartureBeforeArrival"

-- Test 5: Valid insert (should SUCCEED)
INSERT INTO Inventory.Flight (FlightID, FlightNumber, AvailableSeats, DepartureTime, ArrivalTime)
VALUES (999995, 'TEST005', 150, GETDATE(), DATEADD(HOUR, 2, GETDATE()));
-- Success!

-- Cleanup
DELETE FROM Inventory.Flight WHERE FlightID = 999995;
```

### Step 5: View All Constraints

```sql
-- View all check constraints on the table
SELECT 
    con.name AS ConstraintName,
    col.name AS ColumnName,
    con.definition AS ConstraintDefinition,
    con.is_disabled AS IsDisabled
FROM sys.check_constraints con
INNER JOIN sys.objects obj ON con.parent_object_id = obj.object_id
LEFT JOIN sys.columns col ON con.parent_column_id = col.column_id 
    AND con.parent_object_id = col.object_id
WHERE obj.name = 'Flight' AND SCHEMA_NAME(obj.schema_id) = 'Inventory';
```

### Step 6: Create Flyway Migration

Create versioned migration:
```
V017__Add_check_constraints_to_flight_table.sql
```

Migration content:
```sql
-- Clean up existing invalid data
UPDATE Inventory.Flight
SET AvailableSeats = 100
WHERE AvailableSeats <= 0;

UPDATE Inventory.Flight
SET AvailableSeats = 500
WHERE AvailableSeats > 500;

UPDATE Inventory.Flight
SET DepartureTime = DATEADD(HOUR, -1, ArrivalTime)
WHERE DepartureTime >= ArrivalTime;

-- Add check constraints
ALTER TABLE Inventory.Flight
ADD CONSTRAINT CHK_Flight_AvailableSeats_Positive
CHECK (AvailableSeats > 0);

ALTER TABLE Inventory.Flight
ADD CONSTRAINT CHK_Flight_AvailableSeats_MaxCapacity
CHECK (AvailableSeats <= 500);

ALTER TABLE Inventory.Flight
ADD CONSTRAINT CHK_Flight_DepartureBeforeArrival
CHECK (DepartureTime < ArrivalTime);
```

## Hints
- **Clean First**: Always fix invalid data before adding constraints
- **Naming Convention**: Use CHK_TableName_ColumnName_Rule pattern
- **Test Thoroughly**: Try to break each constraint
- **Error Messages**: Constraints provide clear error messages
- **Performance**: Check constraints have minimal performance impact

## Key Concepts Learned
- **Check Constraints**: Enforce column value rules
- **Data Validation**: Database-level validation
- **Business Rules**: Encode rules in schema
- **Constraint Naming**: Following naming conventions
- **Data Cleansing**: Fixing data before constraint addition

## Advanced Check Constraint Examples

```sql
-- Example 1: Range constraint
ALTER TABLE Products
ADD CONSTRAINT CHK_Product_Price_Range
CHECK (Price >= 0 AND Price <= 10000);

-- Example 2: String pattern
ALTER TABLE Customers
ADD CONSTRAINT CHK_Customer_PhoneFormat
CHECK (Phone LIKE '[0-9][0-9][0-9]-[0-9][0-9][0-9]-[0-9][0-9][0-9][0-9]');

-- Example 3: Conditional constraint
ALTER TABLE Orders
ADD CONSTRAINT CHK_Order_ShippedDate
CHECK (ShippedDate IS NULL OR ShippedDate >= OrderDate);

-- Example 4: Multiple column constraint
ALTER TABLE Employees
ADD CONSTRAINT CHK_Employee_Salary_Experience
CHECK (
    (YearsExperience < 2 AND Salary <= 50000) OR
    (YearsExperience >= 2 AND YearsExperience < 5 AND Salary <= 75000) OR
    (YearsExperience >= 5 AND Salary <= 150000)
);

-- Example 5: Enum-like constraint
ALTER TABLE Orders
ADD CONSTRAINT CHK_Order_Status
CHECK (Status IN ('Pending', 'Processing', 'Shipped', 'Delivered', 'Cancelled'));
```

## Common Pitfalls to Avoid
❌ **Adding constraint with invalid data**: Constraint creation fails  
✅ **Solution**: Clean data first, then add constraint

❌ **Overly complex constraints**: Hard to understand and maintain  
✅ **Solution**: Keep constraints simple, use triggers for complex logic

❌ **No documentation**: Team doesn't know about constraints  
✅ **Solution**: Document constraints in schema and team wiki

❌ **Forgetting NULLs**: NULL passes most checks  
✅ **Solution**: Add NOT NULL if needed

## Success Criteria
✅ All invalid data identified and cleaned  
✅ Check constraint for positive seats added  
✅ Check constraint for maximum capacity added  
✅ Check constraint for time sequence added  
✅ All test cases pass (invalid inserts fail, valid inserts succeed)  
✅ Constraints documented with clear names  
✅ Migration script created and tested  
✅ Migration committed to source control

## Troubleshooting
- **Constraint won't add**: Check for data that violates the constraint
- **NULL values causing issues**: Check if NULLs should be allowed
- **Performance degradation**: Check constraints are usually fast; investigate if not
- **Application errors**: Update app code to validate before attempting insert

## Disabling/Enabling Constraints

Sometimes you need to temporarily disable constraints:

```sql
-- Disable constraint (for bulk operations)
ALTER TABLE Inventory.Flight
NOCHECK CONSTRAINT CHK_Flight_AvailableSeats_Positive;

-- Bulk insert data that might violate constraint
-- ... your bulk operations ...

-- Re-enable and validate all data
ALTER TABLE Inventory.Flight
WITH CHECK CHECK CONSTRAINT CHK_Flight_AvailableSeats_Positive;
-- WITH CHECK validates existing data
-- Without it, only new data is checked
```

## Real-World Applications
- **Financial Systems**: Validate transaction amounts, dates
- **Healthcare**: Ensure valid date of birth, age ranges
- **E-commerce**: Validate prices, quantities, discounts
- **HR Systems**: Salary ranges, employment dates
- **Booking Systems**: Valid capacity, date ranges

## Advanced Challenge (Optional)
1. Add a check constraint that validates email format
2. Create a constraint that ensures discount percentage is between 0 and 100
3. Add a multi-column constraint that ensures EndDate > StartDate for campaigns
4. Create a constraint that validates phone number formats
5. Implement a constraint with complex business logic using a scalar function

## Next Steps
Excellent work on data validation! Move on to **Validation Quest 2** to learn about production deployment validation and Flyway Check reports!
