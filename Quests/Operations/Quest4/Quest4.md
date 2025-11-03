**RUN THE SQL SCRIPT FIRST TO CREATE THE NEEDED QUEST ITEMS**

# Operations Quest 4: Performance Optimization with Indexes

**Difficulty:** ⭐⭐⭐ Intermediate-Advanced  
**Time:** 35-45 minutes  
**Prerequisites:** Completed Operations Quest 3

## Learning Objectives
By completing this quest, you will learn:
- Table partitioning strategies for large datasets
- Creating partition functions and schemes
- When and why to partition tables
- Performance implications of partitioning
- Migrating existing tables to partitioned tables

## Scenario
The `Inventory.MaintenanceLog` table has grown to millions of rows and is becoming difficult to manage. Queries are slow, maintenance windows are long, and backup/restore operations take forever. Most queries filter by date, and the operations team typically only needs recent data.

Your task is to implement **table partitioning** by year, which will:
- Improve query performance with partition elimination
- Enable faster maintenance operations (rebuild indexes per partition)
- Allow easy archival of old data
- Reduce lock contention

## Your Mission
Partition the `Inventory.MaintenanceLog` table by year using the `MaintenanceDate` column.

## Objective
1. Create a partition function to split data by year
2. Create a partition scheme to map partitions to filegroups
3. Migrate the existing table to use partitioning
4. Verify partition distribution
5. Test query performance improvements

## What is Table Partitioning?

**Partitioning** divides a large table into smaller, more manageable pieces called partitions, while still treating it as a single table in queries.

**Benefits:**
- **Performance**: Query only relevant partitions (partition elimination)
- **Maintenance**: Rebuild indexes per partition instead of entire table
- **Archival**: Move old partitions to cheaper storage or drop them
- **Scalability**: Distribute data across filegroups/disks

**When to Use:**
- ✅ Tables > 10GB
- ✅ Clear partitioning key (usually date)
- ✅ Queries filter by partition key
- ✅ Need fast data archival/purging
- ❌ Small tables (< 1GB)
- ❌ No natural partition key
- ❌ Complex queries that don't use partition key

## Steps

### Step 1: Create Partition Function
The partition function defines the boundaries between partitions.

```sql
-- Create partition function for yearly partitions
CREATE PARTITION FUNCTION pf_MaintenanceLogByYear (DATE)
AS RANGE RIGHT  -- Values >= boundary go in that partition
FOR VALUES (
    '2020-01-01',  -- Partition 1: < 2020
    '2021-01-01',  -- Partition 2: 2020
    '2022-01-01',  -- Partition 3: 2021
    '2023-01-01',  -- Partition 4: 2022
    '2024-01-01',  -- Partition 5: 2023
    '2025-01-01'   -- Partition 6: 2024
                   -- Partition 7: >= 2025
);
```

**Understanding RANGE RIGHT:**
- Value equals boundary = goes RIGHT (into that partition)
- Example: '2023-01-01' goes into the 2023 partition

### Step 2: Create Partition Scheme
The partition scheme maps partitions to filegroups.

```sql
-- For simplicity, map all partitions to PRIMARY filegroup
-- In production, you might use separate filegroups
CREATE PARTITION SCHEME ps_MaintenanceLogByYear
AS PARTITION pf_MaintenanceLogByYear
ALL TO ([PRIMARY]);

-- Alternative: Map to different filegroups
-- TO (FG_2019, FG_2020, FG_2021, FG_2022, FG_2023, FG_2024, FG_2025);
```

### Step 3: Migrate Existing Table to Partitioned Structure

**Option A: Create New Partitioned Table (Recommended for large tables)**

```sql
-- Step 1: Create new partitioned table
CREATE TABLE Inventory.MaintenanceLog_New (
    LogID INT IDENTITY(1,1),
    EquipmentID INT NOT NULL,
    MaintenanceDate DATE NOT NULL,
    MaintenanceType NVARCHAR(50) NOT NULL,
    TechnicianID INT,
    Notes NVARCHAR(MAX),
    Cost DECIMAL(10,2),
    CONSTRAINT PK_MaintenanceLog_New PRIMARY KEY (LogID, MaintenanceDate)
) ON ps_MaintenanceLogByYear(MaintenanceDate);
-- Note: Partition key (MaintenanceDate) must be part of the PK

-- Step 2: Copy data (this may take time for large tables)
SET IDENTITY_INSERT Inventory.MaintenanceLog_New ON;
INSERT INTO Inventory.MaintenanceLog_New (LogID, EquipmentID, MaintenanceDate, MaintenanceType, TechnicianID, Notes, Cost)
SELECT LogID, EquipmentID, MaintenanceDate, MaintenanceType, TechnicianID, Notes, Cost
FROM Inventory.MaintenanceLog;
SET IDENTITY_INSERT Inventory.MaintenanceLog_New OFF;

-- Step 3: Drop old table and rename new one
DROP TABLE Inventory.MaintenanceLog;
EXEC sp_rename 'Inventory.MaintenanceLog_New', 'MaintenanceLog';

-- Step 4: Recreate indexes
CREATE NONCLUSTERED INDEX IX_MaintenanceLog_EquipmentID
ON Inventory.MaintenanceLog(EquipmentID);

CREATE NONCLUSTERED INDEX IX_MaintenanceLog_TechnicianID
ON Inventory.MaintenanceLog(TechnicianID);
```

**Option B: Rebuild Existing Table (Faster but causes downtime)**

```sql
-- Requires exclusive lock - not recommended for production
CREATE CLUSTERED INDEX IX_MaintenanceLog_Clustered
ON Inventory.MaintenanceLog(LogID, MaintenanceDate)
WITH (DROP_EXISTING = ON)
ON ps_MaintenanceLogByYear(MaintenanceDate);
```

### Step 4: Verify Partitioning

```sql
-- View partition distribution
SELECT 
    p.partition_number AS PartitionNumber,
    f.name AS PartitionFunction,
    r.value AS BoundaryValue,
    p.rows AS RowCount
FROM sys.partitions p
INNER JOIN sys.indexes i ON p.object_id = i.object_id AND p.index_id = i.index_id
INNER JOIN sys.partition_schemes s ON i.data_space_id = s.data_space_id
INNER JOIN sys.partition_functions f ON s.function_id = f.function_id
LEFT JOIN sys.partition_range_values r ON f.function_id = r.function_id 
    AND p.partition_number = r.boundary_id + 1
WHERE p.object_id = OBJECT_ID('Inventory.MaintenanceLog')
ORDER BY p.partition_number;

-- Test partition elimination
SET STATISTICS IO ON;

-- Query with partition key - should scan only relevant partition(s)
SELECT *
FROM Inventory.MaintenanceLog
WHERE MaintenanceDate >= '2023-01-01' AND MaintenanceDate < '2024-01-01';

-- Query without partition key - scans all partitions
SELECT *
FROM Inventory.MaintenanceLog
WHERE EquipmentID = 12345;

SET STATISTICS IO OFF;
```

### Step 5: Create Flyway Migration

Create a single versioned migration:
```
V013__Partition_MaintenanceLog_by_year.sql
```

Include all steps:
- Create partition function
- Create partition scheme
- Create new partitioned table
- Migrate data
- Drop old table
- Rename new table
- Recreate indexes

## Hints
- **Partition Key in Primary Key**: Required for partitioned tables in SQL Server
- **Data Movement**: Large data copies can take hours - test with realistic volumes
- **Downtime Planning**: Option A (new table) allows for parallel operation
- **Index Strategy**: Recreate indexes AFTER data migration
- **Testing**: Always test with actual query patterns

## Key Concepts Learned
- **Table Partitioning**: Dividing tables horizontally
- **Partition Function**: Defines how to split data
- **Partition Scheme**: Maps partitions to storage
- **Partition Elimination**: Query optimizer skips irrelevant partitions
- **Aligned Indexes**: Indexes partitioned the same way as the table

## Performance Testing

### Before Partitioning:
```sql
-- Query scans entire table
SELECT COUNT(*) FROM Inventory.MaintenanceLog
WHERE MaintenanceDate >= '2023-01-01';
-- Logical reads: ~10,000+
```

### After Partitioning:
```sql
-- Query scans only 2023 partition
SELECT COUNT(*) FROM Inventory.MaintenanceLog
WHERE MaintenanceDate >= '2023-01-01' AND MaintenanceDate < '2024-01-01';
-- Logical reads: ~1,000 (10x improvement!)
```

## Common Pitfalls to Avoid
❌ **Partition key not in PK**: SQL Server requires this  
✅ **Solution**: Include partition column in primary key

❌ **Too many partitions**: Overhead exceeds benefits  
✅ **Solution**: Keep partitions reasonable (< 1000)

❌ **Wrong boundary values**: Data goes into wrong partitions  
✅ **Solution**: Test partition boundaries carefully

❌ **Forgetting indexes**: Partitioned table is slow  
✅ **Solution**: Recreate all necessary indexes

## Success Criteria
✅ Partition function `pf_MaintenanceLogByYear` created  
✅ Partition scheme `ps_MaintenanceLogByYear` created  
✅ `Inventory.MaintenanceLog` table is partitioned by MaintenanceDate  
✅ All data migrated successfully (row counts match)  
✅ Indexes recreated on new table  
✅ Partition distribution query shows data across partitions  
✅ Query performance improved for date-filtered queries  
✅ Migration committed to source control

## Troubleshooting
- **"Partition column not in PK"**: Add MaintenanceDate to the PK constraint
- **IDENTITY_INSERT fails**: Ensure you're table owner or have permissions
- **Slow data copy**: Use batching for very large tables
- **Partition elimination not working**: Ensure WHERE clause uses partition key

## Maintenance Operations on Partitioned Tables

```sql
-- Rebuild a single partition's index
ALTER INDEX ALL ON Inventory.MaintenanceLog
REBUILD PARTITION = 5;  -- Just the 2023 partition

-- Switch out old partition for archival
-- (Advanced - requires staging table)
ALTER TABLE Inventory.MaintenanceLog
SWITCH PARTITION 1 TO Inventory.MaintenanceLog_Archive PARTITION 1;

-- Add new partition for 2026
ALTER PARTITION SCHEME ps_MaintenanceLogByYear
NEXT USED [PRIMARY];

ALTER PARTITION FUNCTION pf_MaintenanceLogByYear()
SPLIT RANGE ('2026-01-01');
```

## Real-World Applications
- **Log Tables**: Partition by date, archive old logs
- **Sales Data**: Partition by order date, year, or quarter
- **IoT Data**: Partition sensor data by timestamp
- **Audit Tables**: Partition by audit date for easy compliance queries

## Advanced Challenge (Optional)
1. Add sliding window maintenance to automatically drop old partitions
2. Create a stored procedure to add new yearly partitions automatically
3. Implement partition switching for zero-downtime archival
4. Set up different filegroups for each partition on separate disks

## Next Steps
Excellent work on table partitioning! Move on to **Operations Quest 5** to learn about adding advanced constraints and optimizations!
