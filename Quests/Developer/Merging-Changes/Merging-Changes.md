**RUN THE SQL SCRIPT FIRST TO CREATE THE NEEDED QUEST ITEMS**

# Developer Quest - Merging Pending Changes

**Difficulty:** Intermediate  
**Time:** 30-40 minutes  
**Prerequisites:** Flyway Desktop, Git branching knowledge

## Learning Objectives
By completing this quest, you will learn:
- Managing multiple pending database changes
- Selective migration generation in Flyway Desktop
- Schema filtering to include/exclude objects
- Validating migrations before committing
- Handling concurrent development scenarios
- Best practices for branch-based database development

## Scenario
Your team has been working on two major features in parallel:
- **Marketing Team**: Created several objects in the `Marketing` schema for a new campaign analytics system
- **Finance Team**: Created objects in the `Finance` schema for budget tracking

Both teams have been making changes in a shared development environment, and now it's time to promote the Marketing changes to Test and Production. However, the Finance changes are NOT ready yet and must be excluded.

Your task is to carefully select only the Marketing schema objects and generate a clean migration script, ensuring no Finance objects leak into this release.

## Your Mission
Generate a single migration script that includes ALL Marketing schema objects but EXCLUDES all Finance schema objects.

## Objective
1. Review all pending database changes
2. Use Flyway Desktop to selectively include only Marketing schema objects
3. Generate a single, consolidated migration script
4. Validate the migration before committing
5. Ensure no Finance objects are accidentally included

## Objects Overview

### ✅ Marketing Schema (INCLUDE):
- `Marketing.CustomerFeedback` (Table)
- `Marketing.CampaignAnalytics` (Table)
- `Marketing.GetCustomerFeedback` (Stored Procedure)
- `Marketing.GetAverageCampaignCTR` (Function)

### ❌ Finance Schema (EXCLUDE):
- `Finance.BudgetAllocations` (Table)
- `Finance.GetBudgetForDepartment` (Stored Procedure)

## Steps

### Step 1: Review Pending Changes

**Option A: Using Flyway Desktop**
1. Open Flyway Desktop
2. Navigate to the **Schema Model** tab
3. Click **"Review Changes"** or **"Generate Migration"**
4. You'll see all pending changes across both schemas

**Option B: Using SQL Queries**
```sql
-- List all objects in Marketing schema
SELECT 
    name AS ObjectName,
    type_desc AS ObjectType,
    create_date,
    modify_date
FROM sys.objects
WHERE schema_id = SCHEMA_ID('Marketing')
ORDER BY type_desc, name;

-- List all objects in Finance schema
SELECT 
    name AS ObjectName,
    type_desc AS ObjectType,
    create_date,
    modify_date
FROM sys.objects
WHERE schema_id = SCHEMA_ID('Finance')
ORDER BY type_desc, name;
```

### Step 2: Generate Selective Migration in Flyway Desktop

1. **Open Migration Generation**:
   - Click **"Generate Migration"** in Flyway Desktop
   - Review the list of detected changes

2. **Filter by Schema**:
   - Look for schema filter/selection options
   - Select ONLY the `Marketing` schema
   - OR manually deselect all Finance objects

3. **Review Selected Objects**:
   Verify only these objects are selected:
   - ✅ Marketing.CustomerFeedback
   - ✅ Marketing.CampaignAnalytics
   - ✅ Marketing.GetCustomerFeedback
   - ✅ Marketing.GetAverageCampaignCTR

4. **Generate the Migration**:
   - Provide description: "Add Marketing campaign analytics features"
   - Generate the script
   - File: `V012__Add_marketing_campaign_analytics.sql`

### Step 3: Validate the Generated Migration

```sql
-- Review the generated migration script
-- It should contain:

-- 1. Table Creations
CREATE TABLE Marketing.CustomerFeedback (
    FeedbackID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID INT NOT NULL,
    CampaignID INT NOT NULL,
    FeedbackText NVARCHAR(MAX),
    Rating INT CHECK (Rating BETWEEN 1 AND 5),
    FeedbackDate DATETIME DEFAULT GETDATE()
);

CREATE TABLE Marketing.CampaignAnalytics (
    AnalyticsID INT IDENTITY(1,1) PRIMARY KEY,
    CampaignID INT NOT NULL,
    Impressions INT DEFAULT 0,
    Clicks INT DEFAULT 0,
    Conversions INT DEFAULT 0,
    AnalyticsDate DATE DEFAULT CAST(GETDATE() AS DATE)
);

-- 2. Stored Procedure
CREATE PROCEDURE Marketing.GetCustomerFeedback
    @CampaignID INT
AS
BEGIN
    SELECT 
        FeedbackID,
        CustomerID,
        FeedbackText,
        Rating,
        FeedbackDate
    FROM Marketing.CustomerFeedback
    WHERE CampaignID = @CampaignID
    ORDER BY FeedbackDate DESC;
END;

-- 3. Function
CREATE FUNCTION Marketing.GetAverageCampaignCTR(@CampaignID INT)
RETURNS DECIMAL(5,2)
AS
BEGIN
    DECLARE @CTR DECIMAL(5,2);
    
    SELECT @CTR = 
        CASE 
            WHEN Impressions > 0 THEN (CAST(Clicks AS DECIMAL(10,2)) / Impressions) * 100
            ELSE 0 
        END
    FROM Marketing.CampaignAnalytics
    WHERE CampaignID = @CampaignID;
    
    RETURN ISNULL(@CTR, 0);
END;
```

**Important**: Search the script for "Finance" to ensure nothing leaked in:
```sql
-- This should return NO results
SELECT * FROM sys.objects WHERE name LIKE '%Finance%';
```

### Step 4: Validate with Flyway Validate Command

```bash
# Run Flyway validation
flyway validate

# Expected output:
# Successfully validated X migrations
```

This checks:
- Migration naming conventions
- Script checksums
- Correct ordering
- No conflicts with existing migrations

### Step 5: Test the Migration Locally

```bash
# Apply migration to local dev database
flyway migrate

# Verify objects were created
flyway info
```

Or use SQL:
```sql
-- Verify Marketing objects exist
SELECT name, type_desc
FROM sys.objects
WHERE schema_id = SCHEMA_ID('Marketing')
ORDER BY type_desc, name;

-- Verify NO Finance objects were created
SELECT COUNT(*) AS FinanceObjectCount
FROM sys.objects
WHERE schema_id = SCHEMA_ID('Finance');
-- Should be 0 (or unchanged from before)
```

### Step 6: Commit to Source Control

```bash
git add migrations/V012__Add_marketing_campaign_analytics.sql
git commit -m "Add Marketing campaign analytics features

- Created CustomerFeedback table
- Created CampaignAnalytics table
- Added GetCustomerFeedback stored procedure
- Added GetAverageCampaignCTR function

Excludes Finance schema objects which are not ready for release."
git push
```

## Hints
- **Schema Filtering**: Most migration tools let you filter by schema
- **Double-Check**: Always review generated scripts before committing
- **Validation First**: Run `flyway validate` before `flyway migrate`
- **Dependencies**: Ensure Marketing objects don't depend on Finance objects
- **Naming**: Use descriptive migration names that indicate what's included

## Key Concepts Learned
- **Selective Migration**: Choose which objects to include
- **Schema Isolation**: Keep different feature sets separate
- **Migration Validation**: Check scripts before deployment
- **Concurrent Development**: Multiple teams working simultaneously
- **Release Management**: Control what gets deployed when

## Common Pitfalls to Avoid
❌ **Including unwanted objects**: Deploying unfinished features  
✅ **Solution**: Carefully review the object selection list

❌ **Missing dependencies**: Marketing objects reference Finance objects  
✅ **Solution**: Check for cross-schema dependencies before migrating

❌ **Skipping validation**: Deploying broken migrations  
✅ **Solution**: Always run `flyway validate` first

❌ **No testing**: Migration works in dev but fails in test  
✅ **Solution**: Test migrations in a clean environment

## Success Criteria
✅ Generated migration includes ALL Marketing objects  
✅ Generated migration includes NO Finance objects  
✅ Migration script validated with `flyway validate`  
✅ Migration tested locally and all objects created successfully  
✅ No dependencies on Finance schema exist  
✅ Migration committed to source control with clear description  
✅ Running `flyway info` shows the new migration

## Troubleshooting
- **Can't filter schemas**: Generate full script, then manually edit (not recommended)
- **Dependencies found**: Discuss with teams about cross-schema references
- **Validation fails**: Check migration script for syntax errors
- **Objects missing**: Ensure schema model is up-to-date in Flyway Desktop

## Advanced Scenarios

### Scenario 1: Cross-Schema Dependencies
What if Marketing needs a Finance table? Options:
1. Include the dependency in this migration
2. Coordinate release timing with Finance team
3. Create a stub/mock Finance object temporarily

### Scenario 2: Shared Objects
What if both teams modified the same table?
1. Merge changes carefully
2. Coordinate with both teams
3. Test thoroughly with both feature sets

### Scenario 3: Large Change Sets
What if there are 50+ objects?
1. Break into multiple migrations by feature
2. Use scripting to generate migrations
3. Automate validation testing

## Real-World Applications
- **Feature Branching**: Each feature in its own schema during development
- **Multi-Team Coordination**: Large organizations with parallel development
- **Staged Rollouts**: Deploy features incrementally
- **Compliance**: Ensure only approved changes reach production

## Testing Your Selection Skills
After completing this quest, try:
1. Generate another migration for just the Finance objects
2. Create a migration that includes objects from both schemas
3. Filter by object type (only tables, only procedures)

## Next Steps
Great work on managing concurrent changes! Explore other Operations quests to learn about performance optimization with indexes and computed columns!
