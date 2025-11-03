**RUN THE SQL SCRIPT FIRST TO CREATE THE NEEDED QUEST ITEMS**

# Developer Quest 4: Fixing Broken Dependencies

**Difficulty:** ⭐⭐ Beginner-Intermediate  
**Time:** 20-30 minutes  
**Prerequisites:** Completed Developer Quest 3

## Learning Objectives
By completing this quest, you will learn:
- How to identify and fix broken database dependencies
- Understanding object dependencies in SQL Server
- Using system views and tools to find invalid objects
- Managing schema changes that affect dependent objects

## Scenario
**Uh oh!** A developer on your team renamed the `Sales.Campaigns` table to `Sales.Promotions` to better reflect its purpose. However, they forgot that a stored procedure `Sales.GetActiveCampaigns` references the old table name. Now the stored procedure is broken and throwing errors!

Your task is to identify the broken dependency and fix it so the stored procedure works again.

## Your Mission
Find and fix the broken stored procedure so it references the correct table name (`Sales.Promotions` instead of `Sales.Campaigns`).

## Objective
1. Identify that `Sales.GetActiveCampaigns` is broken
2. Locate the invalid object reference
3. Update the stored procedure to use `Sales.Promotions`
4. Capture the fix as a Flyway repeatable migration
5. Test that the stored procedure now works
6. Commit the fix to source control

## Steps

### Step 1: Identify the Problem
1. **Try to execute the stored procedure**:
   ```sql
   EXEC Sales.GetActiveCampaigns;
   ```
   You should get an error: "Invalid object name 'Sales.Campaigns'"

2. **Find invalid objects** (multiple methods):
   
   **Method A - Using System Views**:
   ```sql
   SELECT 
       OBJECT_NAME(object_id) AS ObjectName,
       OBJECT_SCHEMA_NAME(object_id) AS SchemaName,
       type_desc AS ObjectType
   FROM sys.sql_modules
   WHERE definition LIKE '%Sales.Campaigns%';
   ```
   
   **Method B - Using sp_helptext**:
   ```sql
   EXEC sp_helptext 'Sales.GetActiveCampaigns';
   ```
   
   **Method C - SQL Prompt** (if available):
   - Use "Find Invalid Objects" feature
   - Navigate through the list of broken objects

### Step 2: Review the Current Definition
```sql
-- Current (broken) stored procedure:
CREATE PROCEDURE Sales.GetActiveCampaigns
AS
BEGIN
    SELECT CampaignID, CampaignName, StartDate, EndDate
    FROM Sales.Campaigns  -- This table no longer exists!
    WHERE StartDate <= GETDATE() AND EndDate >= GETDATE();
END;
```

### Step 3: Fix the Stored Procedure
```sql
-- Fixed version:
CREATE OR ALTER PROCEDURE Sales.GetActiveCampaigns
AS
BEGIN
    SELECT 
        PromotionID AS CampaignID,  -- Map to old column name for compatibility
        Name AS CampaignName,
        StartDate, 
        EndDate
    FROM Sales.Promotions  -- Updated table name
    WHERE StartDate <= GETDATE() AND EndDate >= GETDATE();
END;
```

### Step 4: Create Repeatable Migration
1. Save the fixed procedure as a repeatable migration:
   - File: `R__Create_Sales_GetActiveCampaigns.sql`
   - Repeatable migrations are perfect for stored procedures

2. **Capture with Flyway Desktop**:
   - Use Flyway Desktop to generate the repeatable migration
   - Or manually create the file in the migrations folder

3. **Commit to Source Control**:
   - Save and commit the migration
   - Push to repository

### Step 5: Test the Fix
```sql
-- Test that it now works
EXEC Sales.GetActiveCampaigns;

-- Verify it returns active promotions
SELECT 'Fixed!' AS Status;
```

## Hints
- **Finding Dependencies**: Use `sys.sql_modules` system view to find objects referencing specific tables
- **ALTER vs CREATE OR ALTER**: Use `CREATE OR ALTER` for flexibility (SQL Server 2016+)
- **Column Mapping**: When table schemas differ, use aliases to maintain compatibility
- **Testing**: Always test stored procedures after fixing them

## Key Concepts Learned
- **Object Dependencies**: Database objects can depend on other objects
- **Schema Drift**: Manual changes can break dependencies
- **Dependency Management**: Always check for dependent objects before renaming
- **System Catalog Views**: Use system views to query metadata

## Advanced: Finding All Dependencies
Want to see all objects that depend on a table? Use this query:
```sql
SELECT 
    OBJECT_NAME(referencing_id) AS DependentObject,
    OBJECT_SCHEMA_NAME(referencing_id) AS SchemaName,
    o.type_desc AS ObjectType
FROM sys.sql_expression_dependencies sed
INNER JOIN sys.objects o ON sed.referencing_id = o.object_id
WHERE referenced_id = OBJECT_ID('Sales.Promotions');
```

## Common Pitfalls to Avoid
❌ **Renaming objects without checking dependencies**: Always check first!  
✅ **Solution**: Use `sp_depends` or system views before making changes

❌ **Forgetting to update all references**: One fix might not be enough  
✅ **Solution**: Search entire codebase for references

❌ **Using versioned migrations for procedures**: Makes updates complicated  
✅ **Solution**: Always use repeatable migrations for stored procedures

## Success Criteria
✅ The stored procedure `Sales.GetActiveCampaigns` executes without errors  
✅ The procedure returns data from `Sales.Promotions` table  
✅ A repeatable migration exists for the fixed procedure  
✅ The migration is committed to source control  
✅ Testing confirms the procedure works correctly

## Troubleshooting
- **Still getting errors**: Verify the table name is exactly `Sales.Promotions`
- **Column not found**: Check that column names in the new table match your SELECT
- **Permission denied**: Ensure you have ALTER PROCEDURE permissions

## Real-World Applications
- **Refactoring**: When renaming tables/columns, update all dependent objects
- **Code Reviews**: Always check for dependencies before approving schema changes
- **Automated Testing**: Include dependency checks in CI/CD pipelines
- **Documentation**: Maintain documentation of object dependencies

## Next Steps
Great debugging! Move on to **Developer Quest 5** to learn about managing static data with Flyway!
