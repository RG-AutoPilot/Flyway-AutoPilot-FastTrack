**RUN THE SQL SCRIPT FIRST TO CREATE THE NEEDED QUEST ITEMS**

# Developer Quest - Your First Migration

**Difficulty:** Beginner  
**Time:** 15-20 minutes  
**Prerequisites:** None - Flyway Desktop installed, sample database connected

## Learning Objectives
By completing this quest, you will learn:
- How to create your first Flyway migration script
- Understanding versioned migrations vs repeatable migrations
- How Flyway tracks applied migrations
- Basic Flyway Desktop workflow

## Scenario
You're starting your first day as a database developer. The business team needs a new table to track promotional campaigns for the airline's marketing department. This is your first opportunity to use Flyway for version-controlled database changes!

## Your Mission
Create a new table called `Sales.Campaigns` that will store information about marketing campaigns. The business requirements are:
- Each campaign must have a unique identifier
- Track the campaign name (max 100 characters)
- Record when the campaign starts and ends
- All campaigns must have valid start and end dates

## Objective
1. Create a new table `Sales.Campaigns` with the following columns:
   - `CampaignID` (INT, Primary Key)
   - `CampaignName` (NVARCHAR(100), NOT NULL)
   - `StartDate` (DATE, NOT NULL)
   - `EndDate` (DATE, NOT NULL)
2. Capture this change as a Flyway migration using Flyway Desktop
3. Commit the migration script to source control

## Steps
1. **Write the SQL**:
   - Open SQL Server Management Studio (SSMS) or Azure Data Studio
   - Connect to your development database
   - Write a `CREATE TABLE` statement for `Sales.Campaigns`
   
2. **Capture with Flyway Desktop**:
   - Open Flyway Desktop
   - Navigate to the **Schema Model** tab
   - Click **Generate Migration** to detect your new table
   - Review the generated migration script
   - Provide a meaningful description: "Create Sales.Campaigns table"
   
3. **Commit to Source Control**:
   - Save the migration script in Flyway Desktop
   - The script will be saved in the `migrations` folder
   - Commit and push your changes to the repository

4. **Verify**:
   - Check that the migration appears in the `flyway_schema_history` table
   - Run `flyway info` to see your migration listed

## Hints
- **Naming Convention**: Flyway migration scripts follow the pattern `V{version}__{description}.sql`
  - Example: `V001__Create_Sales_Campaigns_table.sql`
- **Create Table Syntax**:
  ```sql
  CREATE TABLE Sales.Campaigns (
      CampaignID INT PRIMARY KEY,
      CampaignName NVARCHAR(100) NOT NULL,
      StartDate DATE NOT NULL,
      EndDate DATE NOT NULL
  );
  ```
- **Testing**: After creating the table, verify it exists:
  ```sql
  SELECT * FROM INFORMATION_SCHEMA.TABLES 
  WHERE TABLE_SCHEMA = 'Sales' AND TABLE_NAME = 'Campaigns';
  ```

## Key Concepts Learned
- **Versioned Migrations**: One-time migrations with version numbers that run in order
- **Migration Lifecycle**: Write SQL → Generate Migration → Apply → Track
- **Flyway Schema History**: The `flyway_schema_history` table tracks all applied migrations
- **Idempotency**: Migrations should only run once and be immutable

## Success Criteria
✅ The `Sales.Campaigns` table exists in your development database  
✅ A migration script exists in your `migrations` folder  
✅ The migration is recorded in the `flyway_schema_history` table  
✅ The migration script is committed to source control  
✅ Running `flyway info` shows your migration as "Success"

## Troubleshooting
- **"Table already exists"**: Drop the table first or use `IF NOT EXISTS` (SQL Server 2016+)
- **Permission denied**: Ensure your database user has CREATE TABLE permissions
- **Migration not detected**: Refresh Flyway Desktop's schema comparison

## Next Steps
Once you've completed this quest, explore other Developer quests to learn how to modify existing tables!
