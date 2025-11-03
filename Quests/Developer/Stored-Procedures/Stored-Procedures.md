**RUN THE SQL SCRIPT FIRST TO CREATE THE NEEDED QUEST ITEMS (if applicable)**

# Developer Quest - Complex Stored Procedures and Functions

**Difficulty:** Advanced  
**Time:** 45-60 minutes  
**Prerequisites:** Flyway Desktop, SQL programming experience

## Learning Objectives
By completing this quest, you will learn:
- Creating complex stored procedures with parameters
- Writing scalar and table-valued functions
- Implementing error handling in procedures
- Using transactions for data consistency
- Optimizing procedure performance
- Best practices for stored procedure design
- Version controlling procedures with Flyway repeatable migrations

## Scenario
Your operations team needs a robust stored procedure to query upcoming flights. Additionally, the analytics team needs a function to calculate flight occupancy rates. These database objects must:
- Accept flexible parameters
- Handle errors gracefully
- Perform efficiently with large datasets
- Be properly version-controlled

## Your Mission
Create production-quality stored procedures and functions that meet enterprise standards for error handling, performance, and maintainability.

## Objective
1. Create a stored procedure `Inventory.GetUpcomingFlights` with date range parameters
2. Create a scalar function `Inventory.CalculateOccupancyRate` 
3. Create a table-valued function `Inventory.GetFlightsByRoute`
4. Implement proper error handling
5. Add performance optimizations
6. Version control all objects as repeatable migrations

## Part 1: Parameterized Stored Procedure

### Step 1: Create GetUpcomingFlights Procedure

```sql
-- Create or alter the stored procedure
CREATE OR ALTER PROCEDURE Inventory.GetUpcomingFlights
    @StartDate DATETIME = NULL,
    @EndDate DATETIME = NULL,
    @DepartureCity NVARCHAR(100) = NULL,
    @ArrivalCity NVARCHAR(100) = NULL,
    @MinAvailableSeats INT = 0,
    @SortBy NVARCHAR(20) = 'DepartureTime'  -- Options: DepartureTime, Price, Duration
AS
BEGIN
    SET NOCOUNT ON;  -- Improve performance
    
    -- Input validation
    IF @StartDate IS NULL
        SET @StartDate = GETDATE();  -- Default to now
    
    IF @EndDate IS NULL
        SET @EndDate = DATEADD(DAY, 30, @StartDate);  -- Default to 30 days out
    
    IF @StartDate > @EndDate
    BEGIN
        RAISERROR('StartDate cannot be after EndDate', 16, 1);
        RETURN -1;
    END;
    
    -- Error handling
    BEGIN TRY
        -- Main query
        SELECT 
            f.FlightID,
            f.FlightNumber,
            f.DepartureCity,
            f.ArrivalCity,
            f.DepartureTime,
            f.ArrivalTime,
            f.AvailableSeats,
            f.FlightDurationMinutes,
            DATEDIFF(DAY, GETDATE(), f.DepartureTime) AS DaysUntilDeparture,
            CAST(ROUND(
                (1.0 - (CAST(f.AvailableSeats AS FLOAT) / 500)) * 100, 
                1
            ) AS DECIMAL(5,1)) AS OccupancyPercentage
        FROM Inventory.Flight f
        WHERE f.DepartureTime >= @StartDate
            AND f.DepartureTime <= @EndDate
            AND (@DepartureCity IS NULL OR f.DepartureCity = @DepartureCity)
            AND (@ArrivalCity IS NULL OR f.ArrivalCity = @ArrivalCity)
            AND f.AvailableSeats >= @MinAvailableSeats
        ORDER BY 
            CASE WHEN @SortBy = 'DepartureTime' THEN f.DepartureTime END ASC,
            CASE WHEN @SortBy = 'Duration' THEN f.FlightDurationMinutes END ASC,
            CASE WHEN @SortBy = 'Price' THEN f.BasePrice END ASC;
        
        RETURN 0;  -- Success
    END TRY
    BEGIN CATCH
        -- Log error (in production, you might log to an error table)
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        -- Return error to caller
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
        RETURN -1;  -- Failure
    END CATCH;
END;
GO
```

### Step 2: Test the Procedure

```sql
-- Test 1: Basic call with date range
EXEC Inventory.GetUpcomingFlights 
    @StartDate = '2024-02-01',
    @EndDate = '2024-02-15';

-- Test 2: Filter by specific route
EXEC Inventory.GetUpcomingFlights 
    @StartDate = '2024-02-01',
    @EndDate = '2024-02-28',
    @DepartureCity = 'New York',
    @ArrivalCity = 'Los Angeles';

-- Test 3: Only flights with available seats
EXEC Inventory.GetUpcomingFlights 
    @StartDate = '2024-02-01',
    @EndDate = '2024-02-28',
    @MinAvailableSeats = 50;

-- Test 4: Sort by duration
EXEC Inventory.GetUpcomingFlights 
    @StartDate = '2024-02-01',
    @EndDate = '2024-02-28',
    @SortBy = 'Duration';

-- Test 5: Error handling - invalid date range
EXEC Inventory.GetUpcomingFlights 
    @StartDate = '2024-02-28',
    @EndDate = '2024-02-01';
-- Should return error: "StartDate cannot be after EndDate"

-- Test 6: Default parameters (next 30 days)
EXEC Inventory.GetUpcomingFlights;
```

## Part 2: Scalar Function for Calculations

### Step 1: Create CalculateOccupancyRate Function

```sql
-- Scalar function returns a single value
CREATE OR ALTER FUNCTION Inventory.CalculateOccupancyRate
(
    @FlightID INT
)
RETURNS DECIMAL(5,2)
AS
BEGIN
    DECLARE @OccupancyRate DECIMAL(5,2);
    DECLARE @AvailableSeats INT;
    DECLARE @TotalCapacity INT = 500;  -- Could be fetched from aircraft table
    
    -- Get available seats for the flight
    SELECT @AvailableSeats = AvailableSeats
    FROM Inventory.Flight
    WHERE FlightID = @FlightID;
    
    -- Calculate occupancy rate
    IF @AvailableSeats IS NULL
        SET @OccupancyRate = 0;
    ELSE
        SET @OccupancyRate = 
            CAST((1.0 - (CAST(@AvailableSeats AS FLOAT) / @TotalCapacity)) * 100 AS DECIMAL(5,2));
    
    RETURN @OccupancyRate;
END;
GO
```

### Step 2: Test the Scalar Function

```sql
-- Test 1: Calculate occupancy for specific flight
SELECT 
    FlightID,
    FlightNumber,
    AvailableSeats,
    dbo.CalculateOccupancyRate(FlightID) AS OccupancyRate
FROM Inventory.Flight
WHERE FlightID = 12345;

-- Test 2: Find flights with high occupancy
SELECT 
    FlightID,
    FlightNumber,
    DepartureCity,
    ArrivalCity,
    AvailableSeats,
    Inventory.CalculateOccupancyRate(FlightID) AS OccupancyRate
FROM Inventory.Flight
WHERE Inventory.CalculateOccupancyRate(FlightID) > 80
ORDER BY Inventory.CalculateOccupancyRate(FlightID) DESC;

-- Test 3: Average occupancy by route
SELECT 
    DepartureCity,
    ArrivalCity,
    AVG(Inventory.CalculateOccupancyRate(FlightID)) AS AvgOccupancy,
    COUNT(*) AS FlightCount
FROM Inventory.Flight
GROUP BY DepartureCity, ArrivalCity
ORDER BY AvgOccupancy DESC;
```

## Part 3: Table-Valued Function

### Step 1: Create GetFlightsByRoute Function

```sql
-- Inline table-valued function (better performance than multi-statement)
CREATE OR ALTER FUNCTION Inventory.GetFlightsByRoute
(
    @DepartureCity NVARCHAR(100),
    @ArrivalCity NVARCHAR(100)
)
RETURNS TABLE
AS
RETURN
(
    SELECT 
        FlightID,
        FlightNumber,
        DepartureTime,
        ArrivalTime,
        AvailableSeats,
        FlightDurationMinutes,
        BasePrice,
        DATEDIFF(HOUR, GETDATE(), DepartureTime) AS HoursUntilDeparture,
        CASE 
            WHEN AvailableSeats > 100 THEN 'High Availability'
            WHEN AvailableSeats > 50 THEN 'Medium Availability'
            WHEN AvailableSeats > 0 THEN 'Low Availability'
            ELSE 'Sold Out'
        END AS AvailabilityStatus
    FROM Inventory.Flight
    WHERE DepartureCity = @DepartureCity
        AND ArrivalCity = @ArrivalCity
        AND DepartureTime >= GETDATE()
);
GO
```

### Step 2: Test the Table-Valued Function

```sql
-- Test 1: Query flights between specific cities
SELECT * 
FROM Inventory.GetFlightsByRoute('New York', 'Los Angeles')
ORDER BY DepartureTime;

-- Test 2: Join with other tables
SELECT 
    f.*,
    r.Distance,
    r.EstimatedDuration
FROM Inventory.GetFlightsByRoute('New York', 'Los Angeles') f
INNER JOIN Inventory.FlightRoute r 
    ON f.DepartureCity = r.DepartureCity 
    AND f.ArrivalCity = r.ArrivalCity;

-- Test 3: Find cheapest available flights on route
SELECT TOP 5
    FlightNumber,
    DepartureTime,
    BasePrice,
    AvailabilityStatus
FROM Inventory.GetFlightsByRoute('Chicago', 'Miami')
WHERE AvailabilityStatus <> 'Sold Out'
ORDER BY BasePrice ASC;
```

## Part 4: Advanced - Procedure with Transaction

```sql
-- Complex procedure that modifies data with transaction
CREATE OR ALTER PROCEDURE Inventory.BookFlightSeats
    @FlightID INT,
    @SeatsToBook INT,
    @CustomerID INT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @CurrentSeats INT;
    DECLARE @BookingID INT;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Get current available seats with lock
        SELECT @CurrentSeats = AvailableSeats
        FROM Inventory.Flight WITH (UPDLOCK, ROWLOCK)
        WHERE FlightID = @FlightID;
        
        -- Validate
        IF @CurrentSeats IS NULL
        BEGIN
            RAISERROR('Flight not found', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN -1;
        END;
        
        IF @CurrentSeats < @SeatsToBook
        BEGIN
            RAISERROR('Not enough seats available', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN -2;
        END;
        
        -- Update available seats
        UPDATE Inventory.Flight
        SET AvailableSeats = AvailableSeats - @SeatsToBook
        WHERE FlightID = @FlightID;
        
        -- Create booking record (assuming Sales.Bookings table exists)
        -- INSERT INTO Sales.Bookings (FlightID, CustomerID, SeatsBooked, BookingDate)
        -- VALUES (@FlightID, @CustomerID, @SeatsToBook, GETDATE());
        -- SET @BookingID = SCOPE_IDENTITY();
        
        COMMIT TRANSACTION;
        
        PRINT 'Booking successful!';
        RETURN 0;  -- Success
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
        RETURN -99;  -- General failure
    END CATCH;
END;
GO
```

## Part 5: Create Flyway Repeatable Migrations

### Create separate files for each object:

**File: `R__Create_Inventory_GetUpcomingFlights.sql`**
```sql
-- Repeatable migration for GetUpcomingFlights stored procedure
CREATE OR ALTER PROCEDURE Inventory.GetUpcomingFlights
    @StartDate DATETIME = NULL,
    @EndDate DATETIME = NULL,
    @DepartureCity NVARCHAR(100) = NULL,
    @ArrivalCity NVARCHAR(100) = NULL,
    @MinAvailableSeats INT = 0,
    @SortBy NVARCHAR(20) = 'DepartureTime'
AS
BEGIN
    -- [Full procedure code here]
END;
GO
```

**File: `R__Create_Inventory_CalculateOccupancyRate.sql`**
```sql
-- Repeatable migration for CalculateOccupancyRate function
CREATE OR ALTER FUNCTION Inventory.CalculateOccupancyRate
(
    @FlightID INT
)
RETURNS DECIMAL(5,2)
AS
BEGIN
    -- [Full function code here]
END;
GO
```

**File: `R__Create_Inventory_GetFlightsByRoute.sql`**
```sql
-- Repeatable migration for GetFlightsByRoute function
CREATE OR ALTER FUNCTION Inventory.GetFlightsByRoute
(
    @DepartureCity NVARCHAR(100),
    @ArrivalCity NVARCHAR(100)
)
RETURNS TABLE
AS
RETURN
(
    -- [Full function query here]
);
GO
```

## Hints
- **Repeatable Migrations**: Always use `R__` prefix for procedures/functions
- **CREATE OR ALTER**: Simplifies updates to existing objects
- **Error Handling**: Always use TRY/CATCH in stored procedures
- **Transactions**: Use for operations that modify multiple tables
- **SET NOCOUNT ON**: Improves performance by reducing network traffic
- **Parameter Defaults**: Make procedures more flexible
- **Documentation**: Add comments explaining parameters and logic

## Key Concepts Learned
- **Stored Procedures**: Encapsulating complex business logic
- **Scalar Functions**: Reusable calculations
- **Table-Valued Functions**: Reusable query logic
- **Error Handling**: Graceful failure management
- **Transactions**: Data consistency across operations
- **Repeatable Migrations**: Version controlling database code
- **Performance**: Optimization techniques

## Best Practices for Stored Procedures

### ✅ DO:
- Use parameters to prevent SQL injection
- Implement comprehensive error handling
- Use transactions for data modifications
- Set NOCOUNT ON for better performance
- Provide default parameter values where appropriate
- Document parameters and return values
- Use appropriate isolation levels
- Version control with repeatable migrations

### ❌ DON'T:
- Use dynamic SQL without parameterization
- Ignore error handling
- Have long-running transactions
- Use SELECT * in production code
- Nest procedures too deeply
- Mix data access with business logic excessively

## Success Criteria
✅ `GetUpcomingFlights` stored procedure created with all parameters  
✅ Procedure includes error handling and validation  
✅ `CalculateOccupancyRate` scalar function created and tested  
✅ `GetFlightsByRoute` table-valued function created and tested  
✅ All objects tested with various inputs including edge cases  
✅ Repeatable migrations created for all objects  
✅ All migrations committed to source control  
✅ Objects deploy successfully through Flyway

## Troubleshooting
- **Function not allowed in this context**: Check if using wrong function type
- **Transaction deadlock**: Review isolation level and locking hints
- **Performance issues**: Add appropriate indexes, avoid functions in WHERE clauses
- **Permission denied**: Ensure EXECUTE permissions granted

## Real-World Applications
- **Booking Systems**: Reserve seats with transaction safety
- **Analytics**: Calculate metrics on-the-fly
- **Reporting**: Flexible parameterized reports
- **Data Validation**: Reusable validation logic
- **Business Rules**: Centralized rule enforcement

## Advanced Challenge (Optional)
1. Add pagination support to GetUpcomingFlights (OFFSET/FETCH)
2. Create a procedure that generates a flight availability report
3. Implement a function that calculates optimal pricing based on occupancy
4. Add logging to all procedures (insert into audit table)
5. Create a procedure with dynamic SQL for flexible filtering
6. Implement a function that validates flight schedule conflicts

## Performance Optimization Tips

```sql
-- Tip 1: Use table variables for small result sets
DECLARE @TempFlights TABLE (
    FlightID INT,
    DepartureTime DATETIME
);

-- Tip 2: Use WITH (NOLOCK) hint for read-only queries (when appropriate)
SELECT * FROM Inventory.Flight WITH (NOLOCK);

-- Tip 3: Create indexes on commonly filtered columns
CREATE INDEX IX_Flight_DepartureTime 
ON Inventory.Flight(DepartureTime) 
INCLUDE (FlightNumber, AvailableSeats);

-- Tip 4: Use OPTION (RECOMPILE) for parameter sniffing issues
EXEC Inventory.GetUpcomingFlights 
    @StartDate = '2024-02-01'
OPTION (RECOMPILE);
```

## Congratulations! 🎉

You've completed **ALL quests** in the Flyway AutoPilot FastTrack program!

### What You've Mastered:

**Developer (Beginner) Level:**
- Creating your first migrations
- Modifying existing schemas
- Working with views
- Fixing broken dependencies
- Managing static data

**Operations (Intermediate) Level:**
- Schema normalization
- Large table refactoring
- Managing concurrent changes
- Table partitioning
- Performance optimization
- Cascading deletes
- Unique constraints

**Validation (Advanced) Level:**
- Check constraints
- Production deployment validation
- Flyway callbacks
- Complex stored procedures

You're now equipped to handle database development from beginner to expert level using Flyway!

### Next Steps:
- Apply these skills to your own projects
- Explore Flyway Enterprise features
- Contribute improvements to this FastTrack repo
- Mentor others learning Flyway

**Well done, Flyway Expert!** 🚀
