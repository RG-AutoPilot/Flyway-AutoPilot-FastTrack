**RUN THE SQL SCRIPT FIRST TO CREATE THE NEEDED QUEST ITEMS**

# Developer Quest - Managing Static Data

**Difficulty:** Intermediate  
**Time:** 25-30 minutes  
**Prerequisites:** Flyway Desktop installed, basic understanding of migrations

## Learning Objectives
By completing this quest, you will learn:
- How to version control static/lookup data
- Using Flyway Desktop's static data feature
- Understanding when to track data vs schema
- Handling initial data loads vs updates
- Using skipExecutingMigrations for specific environments

## Scenario
Your team has built a loyalty program for frequent flyers. The `Customers.LoyaltyProgram` table contains configuration data for different program tiers (Bronze, Silver, Gold, Platinum). This data is essential for the application to function and must be consistent across all environments (Dev, Test, Prod).

Currently, this data exists in your Dev database but isn't version-controlled. If someone rebuilds a database or deploys to a new environment, this critical data would be missing!

## Your Mission
Use Flyway Desktop to capture the loyalty program configuration data and ensure it's deployed consistently across all environments.

## Objective
1. Use Flyway Desktop's static data feature to track the `Customers.LoyaltyProgram` table
2. Generate a migration with the initial data load
3. Understand how to prevent duplicate data errors in environments where data already exists
4. Commit the static data migration to source control

## Background: Static Data vs Transactional Data

**Static Data** (version control this!):
- Lookup tables (countries, states, product categories)
- Configuration data (loyalty tiers, system settings)
- Reference data (tax rates, discount rules)
- Rarely changes and is needed for app functionality

**Transactional Data** (don't version control this!):
- Customer records
- Orders and purchases
- User activity logs
- Changes frequently based on business operations

## Steps

### Step 1: Set Up the Loyalty Program Table
The setup script creates a table with tier data:
```sql
-- This is already done by the setup script
CREATE TABLE Customers.LoyaltyProgram (
    TierID INT PRIMARY KEY,
    TierName NVARCHAR(50) NOT NULL,
    MinimumPoints INT NOT NULL,
    DiscountPercentage DECIMAL(5,2) NOT NULL
);

INSERT INTO Customers.LoyaltyProgram VALUES
    (1, 'Bronze', 0, 5.00),
    (2, 'Silver', 10000, 10.00),
    (3, 'Gold', 25000, 15.00),
    (4, 'Platinum', 50000, 20.00);
```

### Step 2: Track Static Data in Flyway Desktop

1. **Open Flyway Desktop**
2. **Navigate to Schema Model tab**
3. **Open Static Data & Comparisons**:
   - Look for the icon in the top-left corner
   - Click to open the static data popup

4. **Select the Table**:
   - Find `Customers.LoyaltyProgram` in the dropdown
   - Click **"+ Track selected tables"**

5. **Save Changes**:
   - Click Save in Flyway Desktop
   - This triggers the initial data capture

6. **Review Generated Files**:
   - Flyway creates files in the `schema-model` folder
   - These track the data state

### Step 3: Generate Migration Script

1. **Generate Migration**:
   - Click "Generate Migration" in Flyway Desktop
   - Flyway will create a migration with INSERT statements
   - Review the migration - it should contain the 4 loyalty tier rows

2. **Example Generated Migration**:
   ```sql
   -- V005__Add_LoyaltyProgram_static_data.sql
   INSERT INTO Customers.LoyaltyProgram (TierID, TierName, MinimumPoints, DiscountPercentage)
   VALUES 
       (1, 'Bronze', 0, 5.00),
       (2, 'Silver', 10000, 10.00),
       (3, 'Gold', 25000, 15.00),
       (4, 'Platinum', 50000, 20.00);
   ```

### Step 4: Handle Existing Data in Other Environments

**Problem**: Test and Prod already have this loyalty data. Running the migration will cause duplicate key errors!

**Solution**: Use `flyway.skipExecutingMigrations`

1. **Create a configuration override** for Test/Prod:
   ```toml
   # In flyway.toml or environment-specific config
   [environments.test]
   skipExecutingMigrations = ["V005__Add_LoyaltyProgram_static_data.sql"]
   
   [environments.prod]
   skipExecutingMigrations = ["V005__Add_LoyaltyProgram_static_data.sql"]
   ```

2. **What This Does**:
   - ✅ Flyway still records the migration in flyway_schema_history
   - ✅ Version numbers stay in sync across environments
   - ❌ The actual INSERT statements are NOT executed
   - Result: No duplicate key errors!

### Step 5: Commit to Source Control
```bash
git add migrations/V005__Add_LoyaltyProgram_static_data.sql
git add schema-model/
git add flyway.toml
git commit -m "Add static data tracking for LoyaltyProgram"
git push
```

## Hints
- **When to Use Static Data Tracking**:
  - ✅ Lookup/reference tables
  - ✅ Configuration data
  - ✅ Small tables (< 10,000 rows)
  - ❌ Large transactional tables
  - ❌ Frequently changing data

- **skipExecutingMigrations Use Cases**:
  - Initial static data captures
  - Hotfixes that are already manually applied to Prod
  - Data fixes that don't need to run in all environments

- **Alternative Approach**:
  Instead of skipExecutingMigrations, you could use:
  ```sql
  -- Make the migration idempotent
  IF NOT EXISTS (SELECT 1 FROM Customers.LoyaltyProgram WHERE TierID = 1)
  BEGIN
      INSERT INTO Customers.LoyaltyProgram VALUES (1, 'Bronze', 0, 5.00);
  END;
  ```

## Key Concepts Learned
- **Static Data Management**: How to version control reference data
- **Flyway Desktop Static Data Feature**: Automated data tracking
- **Migration Customization**: Using skipExecutingMigrations
- **Environment-Specific Behavior**: Different configs for different environments
- **Idempotent Scripts**: Writing migrations that can run multiple times safely

## Common Pitfalls to Avoid
❌ **Tracking transactional data**: Don't version control customer orders!  
✅ **Solution**: Only track static/reference data

❌ **Forgetting skipExecutingMigrations**: Causes duplicate key errors  
✅ **Solution**: Configure properly for environments with existing data

❌ **Hardcoding environment names**: Makes configuration brittle  
✅ **Solution**: Use environment variables or Flyway placeholders

## Success Criteria
✅ The `Customers.LoyaltyProgram` table is tracked in Flyway Desktop  
✅ Static data files exist in the `schema-model` folder  
✅ A migration script with INSERT statements is generated  
✅ Configuration for skipExecutingMigrations is added (if needed)  
✅ All changes are committed to source control  
✅ Running the migration in a clean database creates the table and data

## Troubleshooting
- **Data not captured**: Make sure you clicked "Track selected tables" and saved
- **Migration not generated**: Click "Generate Migration" after saving changes
- **Duplicate key errors**: Add the migration to skipExecutingMigrations config

## Real-World Applications
- **Multi-Environment Deployments**: Ensure consistency across Dev/Test/Prod
- **Disaster Recovery**: Rebuild databases from scratch with all needed data
- **New Team Members**: Onboard quickly with complete database setup
- **Feature Flags**: Version control configuration tables for feature toggles

## Advanced Challenge (Optional)
Try modifying the loyalty tier percentages:
1. Change Gold tier from 15% to 18% in the database
2. Let Flyway Desktop detect the change
3. Generate an UPDATE migration
4. Deploy the change through your pipeline

## Next Steps
Congratulations! You've completed all the **Developer (Beginner)** quests. You now understand:
- Creating migrations
- Modifying schemas
- Working with views
- Fixing dependencies
- Managing static data

Ready for more advanced topics? Move on to the **Operations (Intermediate)** quests to learn about schema refactoring, performance optimization, and more!
