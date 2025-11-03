**RUN THE SQL SCRIPT FIRST TO CREATE THE NEEDED QUEST ITEMS**

# Operations Quest 6: Cascading Deletes and Referential Integrity

**Difficulty:** ⭐⭐⭐ Intermediate  
**Time:** 25-35 minutes  
**Prerequisites:** Completed Operations Quest 5

## Learning Objectives
By completing this quest, you will learn:
- Foreign key constraint options (CASCADE, SET NULL, SET DEFAULT, NO ACTION)
- When to use cascading deletes vs manual cleanup
- Maintaining referential integrity
- Testing constraint behavior
- Potential risks of cascading operations

## Scenario
The `Sales.OrderAuditLog` table tracks all changes to orders for compliance purposes. It has a foreign key to `Sales.Orders`, but when orders are deleted, the audit logs remain. This causes:
- Orphaned audit records (no parent order)
- Data inconsistency issues
- Difficulty tracking which orders are still active
- Compliance concerns (audit logs for non-existent orders)

The operations team wants audit logs automatically deleted when their parent order is deleted, maintaining data consistency.

## Your Mission
Add a foreign key constraint with `ON DELETE CASCADE` to ensure audit logs are automatically removed when orders are deleted.

## Objective
1. Review the current foreign key constraint
2. Drop the existing constraint
3. Add a new constraint with `ON DELETE CASCADE`
4. Test the cascading behavior
5. Document the change for the team

## Understanding Foreign Key Actions

### DELETE Actions:
- **NO ACTION** (default): Prevents deletion if child records exist
- **CASCADE**: Automatically deletes child records
- **SET NULL**: Sets foreign key to NULL in child records
- **SET DEFAULT**: Sets foreign key to default value in child records

### UPDATE Actions:
- **NO ACTION** (default): Prevents update if child records exist
- **CASCADE**: Automatically updates foreign key in child records
- **SET NULL**: Sets foreign key to NULL in child records
- **SET DEFAULT**: Sets foreign key to default value in child records

## Steps

### Step 1: Review Current Constraint

```sql
-- Find existing foreign key constraint
SELECT 
    fk.name AS ForeignKeyName,
    OBJECT_NAME(fk.parent_object_id) AS ChildTable,
    COL_NAME(fkc.parent_object_id, fkc.parent_column_id) AS ChildColumn,
    OBJECT_NAME(fk.referenced_object_id) AS ParentTable,
    COL_NAME(fkc.referenced_object_id, fkc.referenced_column_id) AS ParentColumn,
    fk.delete_referential_action_desc AS DeleteAction,
    fk.update_referential_action_desc AS UpdateAction
FROM sys.foreign_keys fk
INNER JOIN sys.foreign_key_columns fkc 
    ON fk.object_id = fkc.constraint_object_id
WHERE fk.parent_object_id = OBJECT_ID('Sales.OrderAuditLog');
```

### Step 2: Test Current Behavior

```sql
-- Insert test order
INSERT INTO Sales.Orders (OrderID, CustomerID, OrderDate)
VALUES (999999, 1, GETDATE());

-- Insert test audit log
INSERT INTO Sales.OrderAuditLog (AuditID, OrderID, ChangeDate, ChangeType, ChangedBy)
VALUES (999999, 999999, GETDATE(), 'Created', 'TestUser');

-- Try to delete the order
DELETE FROM Sales.Orders WHERE OrderID = 999999;
-- This will FAIL with current constraint: 
-- "The DELETE statement conflicted with the REFERENCE constraint"

-- Verify audit log still exists
SELECT * FROM Sales.OrderAuditLog WHERE AuditID = 999999;

-- Cleanup
DELETE FROM Sales.OrderAuditLog WHERE AuditID = 999999;
DELETE FROM Sales.Orders WHERE OrderID = 999999;
```

### Step 3: Drop Existing Foreign Key

```sql
-- Find constraint name (may vary)
DECLARE @ConstraintName NVARCHAR(200);
SELECT @ConstraintName = name 
FROM sys.foreign_keys 
WHERE parent_object_id = OBJECT_ID('Sales.OrderAuditLog')
    AND referenced_object_id = OBJECT_ID('Sales.Orders');

-- Drop the constraint
DECLARE @SQL NVARCHAR(MAX);
SET @SQL = 'ALTER TABLE Sales.OrderAuditLog DROP CONSTRAINT ' + @ConstraintName;
EXEC sp_executesql @SQL;

-- OR if you know the exact name:
-- ALTER TABLE Sales.OrderAuditLog 
-- DROP CONSTRAINT FK_OrderAuditLog_Orders;
```

### Step 4: Add New Constraint with CASCADE

```sql
-- Add foreign key with ON DELETE CASCADE
ALTER TABLE Sales.OrderAuditLog
ADD CONSTRAINT FK_OrderAuditLog_Orders_Cascade
FOREIGN KEY (OrderID) 
REFERENCES Sales.Orders(OrderID)
ON DELETE CASCADE
ON UPDATE NO ACTION;  -- Usually don't cascade updates to PK
```

### Step 5: Test Cascading Behavior

```sql
-- Insert test order
INSERT INTO Sales.Orders (OrderID, CustomerID, OrderDate)
VALUES (999999, 1, GETDATE());

-- Insert multiple audit logs
INSERT INTO Sales.OrderAuditLog (AuditID, OrderID, ChangeDate, ChangeType, ChangedBy)
VALUES 
    (999991, 999999, GETDATE(), 'Created', 'TestUser'),
    (999992, 999999, DATEADD(HOUR, 1, GETDATE()), 'Updated', 'TestUser'),
    (999993, 999999, DATEADD(HOUR, 2, GETDATE()), 'Shipped', 'TestUser');

-- Verify audit logs exist
SELECT * FROM Sales.OrderAuditLog WHERE OrderID = 999999;
-- Should return 3 rows

-- Delete the order
DELETE FROM Sales.Orders WHERE OrderID = 999999;
-- This now SUCCEEDS!

-- Verify audit logs are GONE
SELECT * FROM Sales.OrderAuditLog WHERE OrderID = 999999;
-- Should return 0 rows (CASCADE deleted them)
```

### Step 6: Create Flyway Migration

Create versioned migration:
```
V015__Add_cascade_delete_to_order_audit_log.sql
```

Migration content:
```sql
-- Drop existing foreign key constraint
-- (Use actual constraint name from your schema)
ALTER TABLE Sales.OrderAuditLog 
DROP CONSTRAINT FK_OrderAuditLog_Orders;

-- Add new constraint with CASCADE
ALTER TABLE Sales.OrderAuditLog
ADD CONSTRAINT FK_OrderAuditLog_Orders
FOREIGN KEY (OrderID) 
REFERENCES Sales.Orders(OrderID)
ON DELETE CASCADE;
```

## Hints
- **Find Constraint Names**: Use sys.foreign_keys to find exact names
- **Test Thoroughly**: Always test CASCADE behavior before production
- **Document Changes**: Make it clear that deletes will cascade
- **Consider Alternatives**: Sometimes soft deletes are better than CASCADE
- **Audit Requirements**: Ensure CASCADE aligns with compliance needs

## Key Concepts Learned
- **Cascading Deletes**: Automatically remove related records
- **Referential Integrity**: Maintaining valid relationships
- **Constraint Actions**: Different behaviors for constraint violations
- **Foreign Key Options**: CASCADE, SET NULL, SET DEFAULT, NO ACTION
- **Data Consistency**: Preventing orphaned records

## When to Use CASCADE DELETE

### ✅ Good Use Cases:
- Audit logs tied to specific transactions
- Order line items when orders are deleted
- Session data when users are deleted
- Temporary or derived data

### ❌ Avoid When:
- Historical data must be preserved
- Compliance requires audit trail of all changes
- Soft deletes are company policy
- Multiple tables reference the same parent

## Common Pitfalls to Avoid
❌ **Cascading to important historical data**: Lost forever!  
✅ **Solution**: Use soft deletes (IsDeleted flag) instead

❌ **Multiple cascade paths**: Can cause unexpected deletions  
✅ **Solution**: Carefully map all relationships

❌ **No testing**: Accidentally delete critical data  
✅ **Solution**: Test in dev with realistic data

❌ **Forgetting to document**: Team doesn't know about cascade  
✅ **Solution**: Document in schema and share with team

## Success Criteria
✅ Old foreign key constraint removed  
✅ New constraint with `ON DELETE CASCADE` added  
✅ Test shows audit logs are deleted when order is deleted  
✅ No orphaned audit records remain  
✅ Migration script created and tested  
✅ Documentation added explaining the behavior  
✅ Migration committed to source control

## Troubleshooting
- **"Could not drop constraint"**: Check exact constraint name
- **Cascade still not working**: Verify constraint was recreated correctly
- **Unexpected deletions**: Review all cascade relationships
- **Performance issues**: Cascading can be slow on large datasets

## Alternative Approaches

### Soft Deletes (Often Better):
```sql
-- Add IsDeleted flag to Orders table
ALTER TABLE Sales.Orders
ADD IsDeleted BIT NOT NULL DEFAULT 0;

-- "Delete" orders by setting flag
UPDATE Sales.Orders SET IsDeleted = 1 WHERE OrderID = 123;

-- Filter views to hide deleted orders
CREATE VIEW Sales.vw_ActiveOrders AS
SELECT * FROM Sales.Orders WHERE IsDeleted = 0;
```

### Manual Cleanup with Triggers:
```sql
CREATE TRIGGER trg_Orders_Delete
ON Sales.Orders
INSTEAD OF DELETE
AS
BEGIN
    -- Custom cleanup logic
    DELETE FROM Sales.OrderAuditLog 
    WHERE OrderID IN (SELECT OrderID FROM deleted);
    
    DELETE FROM Sales.Orders 
    WHERE OrderID IN (SELECT OrderID FROM deleted);
END;
```

## Real-World Applications
- **Session Management**: Delete session data when user logs out
- **Shopping Carts**: Remove cart items when cart is deleted
- **Temporary Files**: Delete file records when parent entity is deleted
- **Cache Tables**: Clean up derived/cached data automatically

## Advanced Challenge (Optional)
1. Add CASCADE to multiple related tables (OrderItems, OrderPayments)
2. Create a stored procedure to safely delete orders with logging
3. Implement soft deletes as an alternative to CASCADE
4. Set up a trigger to log cascade deletions for auditing

## Next Steps
Great work on managing referential integrity! Move on to **Operations Quest 7** to learn about unique constraints and data validation!
