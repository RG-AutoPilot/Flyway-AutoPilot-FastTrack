**WE HAVE PROVIDED THE NEEDED SQL FOR THE CALLBACK SCRIPT**

# Other Quest - Flyway Callbacks for Advanced Automation

**Difficulty:** Advanced  
**Time:** 40-50 minutes  
**Prerequisites:** Understanding of Flyway lifecycle, basic scripting

## Learning Objectives
By completing this quest, you will learn:
- Understanding Flyway callback lifecycle
- Creating callback scripts for pre/post operations
- Implementing afterClean callbacks
- Using callbacks for automation and validation
- Best practices for callback naming and organization
- Advanced callback use cases

## Scenario
Your CI/CD pipeline uses `flyway clean` to reset the database before running migrations during the Build stage. However, after `clean` completes, there are some cleanup operations that need to happen:
- Verify all objects are truly deleted
- Reset specific configuration settings
- Create temporary objects needed for migration
- Run validation checks before migration

Currently, this is done manually or with separate scripts, making the process error-prone. You need to automate this using Flyway's callback mechanism.

## Your Mission
Create an `afterClean` callback script that runs automatically after `flyway clean` completes, ensuring the database is in the correct state for migrations.

## Objective
1. Understand the Flyway callback lifecycle
2. Create an `afterClean.sql` callback script
3. Implement verification checks in the callback
4. Test the callback in the pipeline
5. Validate that it executes at the right time

## Understanding Flyway Callbacks

Flyway callbacks are scripts that run automatically at specific points in the migration lifecycle.

### Callback Lifecycle Events:

**Before/After Migration:**
- `beforeMigrate`: Before any migration runs
- `afterMigrate`: After all migrations complete

**Before/After Each:**
- `beforeEachMigrate`: Before each migration script
- `afterEachMigrate`: After each migration script

**Before/After Validation:**
- `beforeValidate`: Before validation runs
- `afterValidate`: After validation completes

**Before/After Clean:**
- `beforeClean`: Before clean starts
- `afterClean`: After clean completes  ← **You're implementing this!**

**Before/After Undo:**
- `beforeUndo`: Before undo runs
- `afterUndo`: After undo completes

**Other Events:**
- `beforeInfo`, `afterInfo`
- `beforeBaseline`, `afterBaseline`
- `beforeRepair`, `afterRepair`

### Callback Naming Convention:
```
[prefix][event].sql
```

Examples:
- `afterClean.sql`
- `beforeMigrate.sql`
- `afterEachMigrate__audit.sql` (with description)

### Callback Location:
Place callbacks in the **migrations folder** or a dedicated **callbacks folder**.

## Steps

### Step 1: Understand the Clean Command

```bash
# What flyway clean does:
flyway clean

# Result:
# - Drops all objects in the configured schemas
# - Removes flyway_schema_history table
# - Leaves database nearly empty
```

After clean, you might need to:
- Verify cleanup was complete
- Create database settings
- Prepare for migrations

### Step 2: Create the afterClean Callback

Create file: `migrations/afterClean.sql`

```sql
/*
 * Flyway Callback: afterClean
 * Purpose: Verify database cleanup and prepare for migrations
 * Runs: Automatically after 'flyway clean' completes
 * Author: [Your Name]
 * Date: 2024-01-22
 */

PRINT '=================================';
PRINT 'afterClean Callback Starting';
PRINT 'Verifying database cleanup...';
PRINT '=================================';

-- Step 1: Verify all user objects are deleted
DECLARE @ObjectCount INT;

SELECT @ObjectCount = COUNT(*)
FROM sys.objects
WHERE type IN ('U', 'V', 'P', 'FN', 'IF', 'TF')  -- Tables, Views, Procedures, Functions
    AND is_ms_shipped = 0;  -- Exclude system objects

IF @ObjectCount > 0
BEGIN
    PRINT 'WARNING: ' + CAST(@ObjectCount AS NVARCHAR(10)) + ' user objects still exist!';
    
    -- List remaining objects for debugging
    SELECT 
        SCHEMA_NAME(schema_id) AS SchemaName,
        name AS ObjectName,
        type_desc AS ObjectType
    FROM sys.objects
    WHERE type IN ('U', 'V', 'P', 'FN', 'IF', 'TF')
        AND is_ms_shipped = 0;
    
    -- Optionally, clean them up
    DECLARE @SQL NVARCHAR(MAX);
    DECLARE @SchemaName NVARCHAR(128);
    DECLARE @ObjectName NVARCHAR(128);
    DECLARE @ObjectType NVARCHAR(128);
    
    DECLARE cleanup_cursor CURSOR FOR
        SELECT 
            SCHEMA_NAME(schema_id),
            name,
            type_desc
        FROM sys.objects
        WHERE type IN ('U', 'V', 'P', 'FN', 'IF', 'TF')
            AND is_ms_shipped = 0;
    
    OPEN cleanup_cursor;
    FETCH NEXT FROM cleanup_cursor INTO @SchemaName, @ObjectName, @ObjectType;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @SQL = 'DROP ' + 
            CASE @ObjectType
                WHEN 'USER_TABLE' THEN 'TABLE '
                WHEN 'VIEW' THEN 'VIEW '
                WHEN 'SQL_STORED_PROCEDURE' THEN 'PROCEDURE '
                WHEN 'SQL_SCALAR_FUNCTION' THEN 'FUNCTION '
                WHEN 'SQL_INLINE_TABLE_VALUED_FUNCTION' THEN 'FUNCTION '
                WHEN 'SQL_TABLE_VALUED_FUNCTION' THEN 'FUNCTION '
            END + @SchemaName + '.' + @ObjectName;
        
        PRINT 'Cleaning up: ' + @SQL;
        EXEC sp_executesql @SQL;
        
        FETCH NEXT FROM cleanup_cursor INTO @SchemaName, @ObjectName, @ObjectType;
    END;
    
    CLOSE cleanup_cursor;
    DEALLOCATE cleanup_cursor;
END
ELSE
BEGIN
    PRINT 'SUCCESS: Database is clean. No user objects found.';
END;

-- Step 2: Verify all schemas exist that migrations will need
PRINT 'Checking required schemas...';

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'Sales')
BEGIN
    PRINT 'Creating Sales schema...';
    EXEC('CREATE SCHEMA Sales');
END;

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'Customers')
BEGIN
    PRINT 'Creating Customers schema...';
    EXEC('CREATE SCHEMA Customers');
END;

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'Inventory')
BEGIN
    PRINT 'Creating Inventory schema...';
    EXEC('CREATE SCHEMA Inventory');
END;

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'Marketing')
BEGIN
    PRINT 'Creating Marketing schema...';
    EXEC('CREATE SCHEMA Marketing');
END;

PRINT 'All required schemas exist.';

-- Step 3: Set database configuration
PRINT 'Configuring database settings...';

-- Set recovery model for faster bulk operations
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = DB_NAME() AND recovery_model_desc = 'FULL')
BEGIN
    PRINT 'Setting recovery model to SIMPLE for faster migrations...';
    DECLARE @DbName NVARCHAR(128) = DB_NAME();
    EXEC('ALTER DATABASE [' + @DbName + '] SET RECOVERY SIMPLE');
END;

-- Step 4: Log completion
PRINT '';
PRINT '=================================';
PRINT 'afterClean Callback Completed';
PRINT 'Database ready for migrations';
PRINT '=================================';
PRINT '';
```

### Step 3: Alternative - Minimal afterClean

If you just need the basics:

```sql
-- migrations/afterClean.sql
-- Simple verification callback

PRINT 'afterClean: Verifying cleanup...';

-- Count remaining objects
DECLARE @Count INT;
SELECT @Count = COUNT(*)
FROM sys.objects
WHERE type IN ('U', 'V', 'P', 'FN')
    AND is_ms_shipped = 0;

IF @Count = 0
    PRINT 'afterClean: Cleanup verified - database is clean';
ELSE
    RAISERROR('afterClean: WARNING - %d objects still exist', 16, 1, @Count);

-- Ensure required schemas exist
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'Sales')
    CREATE SCHEMA Sales;

PRINT 'afterClean: Database prepared for migrations';
```

### Step 4: Test the Callback Locally

```bash
# Run clean to trigger the callback
flyway clean

# Expected output:
# Flyway running: clean
# Successfully dropped all objects
# Executing SQL callback: afterClean
# =================================
# afterClean Callback Starting
# ...
# afterClean Callback Completed
# =================================
```

### Step 5: Verify Callback in Pipeline

1. **Commit the Callback**:
```bash
git add migrations/afterClean.sql
git commit -m "Add afterClean callback for database verification"
git push
```

2. **Trigger CI/CD Pipeline**:
   - Navigate to Azure DevOps
   - Run the Flyway pipeline
   - Watch the Build stage

3. **Check Pipeline Logs**:
```
[Build Stage]
Running: flyway clean
... cleanup operations ...
Executing SQL callback: afterClean
=================================
afterClean Callback Starting
Verifying database cleanup...
=================================
SUCCESS: Database is clean. No user objects found.
All required schemas exist.
=================================
afterClean Callback Completed
Database ready for migrations
=================================

Running: flyway migrate
... migrations execute ...
```

4. **Verify Success**:
   - Callback runs automatically
   - Database verification passes
   - Migrations run successfully

## Additional Callback Examples

### beforeMigrate Callback
```sql
-- migrations/beforeMigrate.sql
-- Backup flyway_schema_history before migrations

PRINT 'beforeMigrate: Creating backup of schema history...';

IF OBJECT_ID('dbo.flyway_schema_history_backup', 'U') IS NOT NULL
    DROP TABLE dbo.flyway_schema_history_backup;

SELECT *
INTO dbo.flyway_schema_history_backup
FROM dbo.flyway_schema_history;

PRINT 'beforeMigrate: Backup created successfully';
```

### afterMigrate Callback
```sql
-- migrations/afterMigrate.sql
-- Update database version info after successful migration

PRINT 'afterMigrate: Updating database version metadata...';

IF OBJECT_ID('dbo.DatabaseInfo', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.DatabaseInfo (
        LastMigrationDate DATETIME,
        MigrationCount INT,
        DatabaseVersion NVARCHAR(50)
    );
    INSERT INTO dbo.DatabaseInfo VALUES (GETDATE(), 0, '1.0.0');
END;

UPDATE dbo.DatabaseInfo
SET LastMigrationDate = GETDATE(),
    MigrationCount = (SELECT COUNT(*) FROM flyway_schema_history WHERE success = 1),
    DatabaseVersion = (
        SELECT TOP 1 version 
        FROM flyway_schema_history 
        WHERE type = 'SQL'
        ORDER BY installed_rank DESC
    );

PRINT 'afterMigrate: Database version updated';
```

### beforeEachMigrate Callback
```sql
-- migrations/beforeEachMigrate.sql
-- Log each migration execution

PRINT 'beforeEachMigrate: Logging migration start...';

IF OBJECT_ID('dbo.MigrationAuditLog', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.MigrationAuditLog (
        LogID INT IDENTITY PRIMARY KEY,
        MigrationScript NVARCHAR(255),
        StartTime DATETIME,
        Status NVARCHAR(50)
    );
END;

-- Flyway provides context variables
INSERT INTO dbo.MigrationAuditLog (MigrationScript, StartTime, Status)
VALUES ('${flyway:filename}', GETDATE(), 'STARTED');

PRINT 'beforeEachMigrate: Migration logged';
```

## Hints
- **Naming Matters**: Exact event names required (case-sensitive on some systems)
- **Location**: Place in migrations folder or configured callbacks location
- **Execution Order**: Multiple callbacks for same event run alphabetically
- **Error Handling**: Callback failures stop the migration process
- **Output**: Use PRINT statements for visibility in logs

## Key Concepts Learned
- **Callback Lifecycle**: When different callbacks execute
- **Automation**: Automatic script execution at lifecycle events
- **Validation**: Pre/post operation checks
- **Database Preparation**: Setting up environment for migrations
- **Advanced Flyway Features**: Beyond basic migrate/clean

## Common Callback Use Cases

1. **Database Backups**: Before major operations
2. **Validation**: Verify preconditions before migrations
3. **Cleanup**: Remove temporary objects after migrations
4. **Logging**: Audit trail of all operations
5. **Configuration**: Set database options
6. **Notifications**: Send alerts when operations complete
7. **Data Seeding**: Insert test data after migrations

## Common Pitfalls to Avoid
❌ **Callback takes too long**: Slows down deployments  
✅ **Solution**: Keep callbacks fast and focused

❌ **Callback fails silently**: Issue not detected  
✅ **Solution**: Use RAISERROR for critical failures

❌ **Callback has dependencies**: Needs objects that don't exist yet  
✅ **Solution**: Check for existence before using objects

❌ **Wrong callback event**: Executes at wrong time  
✅ **Solution**: Review lifecycle, choose correct event

## Success Criteria
✅ afterClean.sql callback created in migrations folder  
✅ Callback verifies database cleanup  
✅ Callback creates required schemas  
✅ Callback tested locally with `flyway clean`  
✅ Callback executes automatically in CI/CD pipeline  
✅ Pipeline logs show callback output  
✅ Migrations run successfully after callback  
✅ Callback committed to source control

## Troubleshooting
- **Callback not executing**: Check filename spelling and location
- **Callback fails**: Check SQL syntax and dependencies
- **Wrong execution order**: Rename to control alphabetical order
- **Can't see output**: Check pipeline log verbosity settings

## Real-World Applications
- **Pre-deployment Checks**: Validate environment before deploying
- **Post-deployment Tasks**: Send notifications, update logs
- **Database Seeding**: Insert reference data after schema creation
- **Performance Tuning**: Set database options for optimal migration speed
- **Compliance**: Log all schema changes for audit trails

## Advanced Challenge (Optional)
1. Create a `beforeMigrate` callback that checks for required database permissions
2. Implement an `afterMigrate` callback that runs tests on the migrated schema
3. Create callbacks that send Slack/Teams notifications on deployment success/failure
4. Build a callback that generates API documentation from schema changes
5. Implement drift detection in a callback (compare schema to expected state)

## Next Steps
Fantastic work on callbacks! Explore other quests to learn about creating complex stored procedures and functions!
