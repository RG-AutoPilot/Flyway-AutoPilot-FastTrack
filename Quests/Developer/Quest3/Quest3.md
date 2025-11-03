**RUN THE SQL SCRIPT FIRST TO CREATE THE NEEDED QUEST ITEMS**

# Developer Quest 3: Working with Database Views

**Difficulty:** ⭐⭐ Beginner  
**Time:** 20-25 minutes  
**Prerequisites:** Completed Developer Quest 2

## Learning Objectives
By completing this quest, you will learn:
- How to create and modify database views
- Understanding repeatable migrations vs versioned migrations
- When to use views for data abstraction
- Best practices for view definitions

## Scenario
The reporting team needs an easier way to query customer order information. They want a simplified view that combines data from the `Customers.Customer` table and the `Sales.Orders` table. Instead of writing complex joins every time, you'll create a view that does this for them.

Additionally, after the view is in use, they request adding the `TicketQuantity` column to make the view even more useful.

## Your Mission
**Part 1:** Create a view that combines customer and order information  
**Part 2:** Modify the view to include additional columns

## Objective
1. Create a view `Sales.CustomerOrdersView` that shows:
   - Customer information (CustomerID, FirstName, LastName)
   - Order information (OrderID, OrderDate)
2. Modify the view to also include `TicketQuantity` from the Orders table
3. Understand when to use repeatable vs versioned migrations for views

## Steps

### Part 1: Create the View
1. **Write the CREATE VIEW SQL**:
   ```sql
   CREATE VIEW Sales.CustomerOrdersView AS
   SELECT 
       c.CustomerID,
       c.FirstName,
       c.LastName,
       o.OrderID,
       o.OrderDate
   FROM Customers.Customer c
   INNER JOIN Sales.Orders o ON c.CustomerID = o.CustomerID;
   ```

2. **Capture as a Repeatable Migration**:
   - In Flyway Desktop, save this as a **repeatable migration**
   - Repeatable migrations use the pattern: `R__{description}.sql`
   - Name it: `R__Create_Sales_CustomerOrdersView.sql`

3. **Test the View**:
   ```sql
   SELECT * FROM Sales.CustomerOrdersView;
   ```

### Part 2: Modify the View
1. **Update the View Definition**:
   ```sql
   CREATE OR ALTER VIEW Sales.CustomerOrdersView AS
   SELECT 
       c.CustomerID,
       c.FirstName,
       c.LastName,
       o.OrderID,
       o.OrderDate,
       o.TicketQuantity  -- NEW COLUMN
   FROM Customers.Customer c
   INNER JOIN Sales.Orders o ON c.CustomerID = o.CustomerID;
   ```

2. **Update the Repeatable Migration**:
   - Edit the same `R__Create_Sales_CustomerOrdersView.sql` file
   - Add the new column to the SELECT statement
   - Flyway will detect the change and re-run the migration

3. **Commit to Source Control**:
   - Save and commit your updated migration
   - Push to the repository

## Hints
- **Repeatable vs Versioned Migrations**:
  - **Versioned (V)**: Run once, never change (used for ALTER TABLE, INSERT data)
  - **Repeatable (R)**: Re-run on checksum change (used for CREATE VIEW, CREATE PROCEDURE)
- **CREATE OR ALTER**: This syntax works in SQL Server 2016+ and makes view updates easier
- **Why Views?**:
  - Simplify complex queries
  - Provide data abstraction
  - Centralize business logic
  - Improve security (hide sensitive columns)

## Key Concepts Learned
- **Repeatable Migrations**: Run every time their checksum changes
- **Views**: Virtual tables based on query results
- **Data Abstraction**: Hiding complexity behind simple interfaces
- **View Maintenance**: Views should be version-controlled just like tables

## Common Pitfalls to Avoid
❌ **Using Versioned Migration for Views**: This makes updates harder  
✅ **Solution**: Use Repeatable Migrations (R__) for views and stored procedures

❌ **SELECT * in Views**: This can cause issues when table schemas change  
✅ **Solution**: Explicitly list all columns you need

❌ **Complex Logic in Views**: This can hurt performance  
✅ **Solution**: Keep views simple; use stored procedures for complex logic

## Success Criteria
✅ The view `Sales.CustomerOrdersView` exists and is queryable  
✅ The view includes CustomerID, FirstName, LastName, OrderID, OrderDate, TicketQuantity  
✅ A repeatable migration `R__Create_Sales_CustomerOrdersView.sql` exists  
✅ The migration is committed to source control  
✅ Running `flyway info` shows the repeatable migration  
✅ Querying the view returns correct data with all columns

## Troubleshooting
- **"Invalid object name"**: Ensure the source tables (Customer, Orders) exist
- **Column not found**: Verify the column names match your table schema
- **View not updating**: Check the checksum changed in flyway_schema_history

## Real-World Applications
- **Reporting**: Create views for common reports to simplify analyst queries
- **Security**: Hide sensitive columns while exposing needed data
- **Legacy Systems**: Provide backward compatibility when refactoring schemas
- **API Layers**: Views can serve as stable interfaces to changing schemas

## Next Steps
Excellent work! Move on to **Developer Quest 4** to learn how to fix broken dependencies!
