**RUN THE SQL SCRIPT FIRST TO CREATE THE NEEDED QUEST ITEMS**

# Developer Quest 2: Modifying Existing Tables

**Difficulty:** ⭐ Beginner  
**Time:** 15-20 minutes  
**Prerequisites:** Completed Developer Quest 1

## Learning Objectives
By completing this quest, you will learn:
- How to safely modify existing database tables
- Understanding ALTER TABLE statements
- Managing schema evolution with Flyway
- Testing schema changes before deployment

## Scenario
The Marketing team loves the `Sales.Campaigns` table you created! However, they've realized they need to track one more piece of information: the discount percentage being offered in each campaign. You need to add this new column to the existing table without disrupting any data that might already exist.

## Your Mission
Add a new column to the existing `Sales.Campaigns` table to track discount percentages. The business requirements are:
- Store discount as a percentage (e.g., 15.50%)
- Allow values from 0.00 to 100.00
- The column should be optional (nullable) since existing campaigns might not have discounts
- Use appropriate precision for decimal values

## Objective
1. Add a column `DiscountPercentage` (DECIMAL(5,2), nullable) to the `Sales.Campaigns` table
2. Capture this change as a new Flyway migration
3. Test that existing data remains intact
4. Commit the migration to source control

## Steps
1. **Write the ALTER TABLE SQL**:
   - Open your SQL development tool
   - Connect to your development database
   - Write an `ALTER TABLE` statement to add the new column
   
2. **Test Locally**:
   - If you have data in the table, verify it's not affected
   - Insert a test row with the new column
   - Query the table to confirm the column exists
   
3. **Capture with Flyway Desktop**:
   - Open Flyway Desktop
   - Generate a new migration for this schema change
   - Review the migration script
   - Provide description: "Add DiscountPercentage column to Sales.Campaigns"
   
4. **Commit to Source Control**:
   - Save and commit the migration script
   - Push your changes to the repository

## Hints
- **ALTER TABLE Syntax**:
  ```sql
  ALTER TABLE Sales.Campaigns
  ADD DiscountPercentage DECIMAL(5,2) NULL;
  ```
- **Why DECIMAL(5,2)?**: 
  - 5 total digits
  - 2 digits after decimal point
  - Allows values like 99.99 (perfect for percentages)
- **Testing Your Change**:
  ```sql
  -- Insert a test campaign with discount
  INSERT INTO Sales.Campaigns (CampaignID, CampaignName, StartDate, EndDate, DiscountPercentage)
  VALUES (1, 'Summer Sale', '2024-06-01', '2024-08-31', 15.50);
  
  -- Verify the column exists
  SELECT COLUMN_NAME, DATA_TYPE, IS_NULLABLE
  FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_NAME = 'Campaigns' AND TABLE_SCHEMA = 'Sales';
  ```

## Key Concepts Learned
- **Schema Evolution**: Databases change over time; Flyway helps manage this safely
- **Backward Compatibility**: Making changes that don't break existing functionality
- **Nullable Columns**: When adding columns to populated tables, nullable is often safer
- **Data Type Selection**: Choosing appropriate types for business requirements

## Common Pitfalls to Avoid
❌ **Adding NOT NULL without DEFAULT**: This fails if the table has existing rows  
✅ **Solution**: Make the column nullable OR provide a DEFAULT value

❌ **Wrong data type**: Using INT for percentages loses precision  
✅ **Solution**: Use DECIMAL with appropriate precision

❌ **Forgetting to test**: Always test schema changes before committing  
✅ **Solution**: Run SELECT queries to verify your changes

## Success Criteria
✅ The `DiscountPercentage` column exists in `Sales.Campaigns`  
✅ The column has data type DECIMAL(5,2)  
✅ The column allows NULL values  
✅ A new migration script is created and versioned  
✅ The migration is committed to source control  
✅ Running `flyway info` shows the new migration

## Troubleshooting
- **"Column already exists"**: Check if you've already run this migration
- **Precision errors**: Verify you're using DECIMAL(5,2) not DECIMAL(4,2)
- **Migration not detected**: Make sure you've saved your SQL changes before generating the migration

## Next Steps
Great job! Move on to **Developer Quest 3** to learn about working with database views!
