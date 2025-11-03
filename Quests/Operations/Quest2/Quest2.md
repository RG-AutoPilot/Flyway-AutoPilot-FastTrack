**RUN THE SQL SCRIPT FIRST TO CREATE THE NEEDED QUEST ITEMS**

# Operations Quest 2: Large Table Refactoring

**Difficulty:** ⭐⭐⭐ Intermediate  
**Time:** 30-40 minutes  
**Prerequisites:** Completed Operations Quest 1

## Learning Objectives
By completing this quest, you will learn:
- Splitting large tables for better performance
- Column-level data migration strategies
- Managing relationships during table splits
- Performance considerations for large datasets
- Rollback strategies for complex migrations

## Scenario
The `Customers.CustomerFeedback` table has grown massive over time. It contains thousands of rows with large TEXT fields storing customer comments. This is causing performance issues:
- Slow queries when searching feedback
- Large memory consumption
- Inefficient indexing
- Backup/restore takes too long

The operations team wants you to split the `Comments` column into a separate table to improve query performance and manageability.

## Your Mission
Split the `CustomerFeedback` table by moving the `Comments` column to a new `CustomerFeedbackComments` table with a 1:1 relationship.

## Objective
1. Create a new table `Customers.CustomerFeedbackComments` to store comment data
2. Migrate all comments from the original table
3. Establish a foreign key relationship
4. Remove the `Comments` column from the original table
5. Verify performance improvements

## Database Design

### Current Schema:
```sql
Customers.CustomerFeedback
├── FeedbackID (PK)
├── CustomerID (FK)
├── Rating (1-5)
├── CreatedDate
└── Comments (NVARCHAR(MAX))  -- This is the problem!
```

### Target Schema:
```sql
Customers.CustomerFeedback
├── FeedbackID (PK)
├── CustomerID (FK)
├── Rating (1-5)
└── CreatedDate

Customers.CustomerFeedbackComments (NEW)
├── CommentID (PK)
├── FeedbackID (FK) → Customers.CustomerFeedback
└── Comments (NVARCHAR(MAX))
```

## Why This Helps Performance
- **Smaller Main Table**: Queries on ratings/dates are faster
- **Better Indexing**: Can index the main table more efficiently
- **Selective Loading**: Only load comments when needed
- **Easier Archiving**: Can archive old comments separately
- **Reduced I/O**: Many queries don't need comments at all

## Steps

### Step 1: Analyze Current Table Size
```sql
-- Check current table stats
SELECT 
    t.NAME AS TableName,
    p.rows AS RowCounts,
    SUM(a.total_pages) * 8 AS TotalSpaceKB,
    SUM(a.used_pages) * 8 AS UsedSpaceKB
FROM sys.tables t
INNER JOIN sys.indexes i ON t.OBJECT_ID = i.object_id
INNER JOIN sys.partitions p ON i.object_id = p.OBJECT_ID AND i.index_id = p.index_id
INNER JOIN sys.allocation_units a ON p.partition_id = a.container_id
WHERE t.NAME = 'CustomerFeedback'
    AND t.schema_id = SCHEMA_ID('Customers')
GROUP BY t.Name, p.Rows;
```

### Step 2: Create the New Table
```sql
CREATE TABLE Customers.CustomerFeedbackComments (
    CommentID INT IDENTITY(1,1) PRIMARY KEY,
    FeedbackID INT NOT NULL,
    Comments NVARCHAR(MAX) NOT NULL,
    CONSTRAINT FK_FeedbackComments_Feedback
        FOREIGN KEY (FeedbackID) 
        REFERENCES Customers.CustomerFeedback(FeedbackID)
        ON DELETE CASCADE  -- When feedback is deleted, delete comments too
);

-- Create index for better join performance
CREATE INDEX IX_CustomerFeedbackComments_FeedbackID 
ON Customers.CustomerFeedbackComments(FeedbackID);
```

### Step 3: Migrate Data
```sql
-- Insert comments into new table
INSERT INTO Customers.CustomerFeedbackComments (FeedbackID, Comments)
SELECT 
    FeedbackID,
    Comments
FROM Customers.CustomerFeedback
WHERE Comments IS NOT NULL AND Comments <> '';

-- Verify migration
SELECT 
    'Original' AS Source,
    COUNT(*) AS RecordsWithComments
FROM Customers.CustomerFeedback
WHERE Comments IS NOT NULL AND Comments <> ''
UNION ALL
SELECT 
    'New Table' AS Source,
    COUNT(*) AS RecordsWithComments
FROM Customers.CustomerFeedbackComments;
```

### Step 4: Drop Old Column
```sql
-- Only after verification!
ALTER TABLE Customers.CustomerFeedback
DROP COLUMN Comments;
```

### Step 5: Create Flyway Migration
Create versioned migration:
```
V011__Split_feedback_comments_to_separate_table.sql
```

Include all steps in the migration file, with verification queries commented out.

## Hints
- **ON DELETE CASCADE**: Automatically cleans up orphaned comments
- **NULL Handling**: Only migrate non-null, non-empty comments
- **Testing**: Test with realistic data volumes before deploying
- **Indexes**: Add appropriate indexes to the new table
- **Views**: Consider creating a view to join the tables for backward compatibility

## Key Concepts Learned
- **Vertical Partitioning**: Splitting tables by columns
- **1:1 Relationships**: One feedback = one comment record
- **CASCADE Operations**: Automatic cleanup of related records
- **Performance Tuning**: Strategic table splitting for better performance
- **Data Migration at Scale**: Handling large datasets safely

## Performance Testing

### Before Migration:
```sql
-- Slow query (scans large Comments column)
SELECT FeedbackID, Rating, CreatedDate
FROM Customers.CustomerFeedback
WHERE Rating >= 4;
```

### After Migration:
```sql
-- Faster query (smaller table, no Comments column)
SELECT FeedbackID, Rating, CreatedDate
FROM Customers.CustomerFeedback
WHERE Rating >= 4;

-- Only fetch comments when needed
SELECT 
    f.FeedbackID,
    f.Rating,
    f.CreatedDate,
    c.Comments
FROM Customers.CustomerFeedback f
INNER JOIN Customers.CustomerFeedbackComments c ON f.FeedbackID = c.FeedbackID
WHERE f.FeedbackID = 12345;
```

## Create a Compatibility View (Optional)
```sql
-- Create view for backward compatibility
CREATE VIEW Customers.vw_CustomerFeedbackComplete AS
SELECT 
    f.FeedbackID,
    f.CustomerID,
    f.Rating,
    f.CreatedDate,
    c.Comments
FROM Customers.CustomerFeedback f
LEFT JOIN Customers.CustomerFeedbackComments c ON f.FeedbackID = c.FeedbackID;
```

## Common Pitfalls to Avoid
❌ **Forgetting ON DELETE CASCADE**: Leaves orphaned comment records  
✅ **Solution**: Add CASCADE to foreign key or handle cleanup manually

❌ **Migrating NULL/empty comments**: Wastes space in new table  
✅ **Solution**: Filter out NULL and empty strings

❌ **No rollback plan**: Can't undo if something goes wrong  
✅ **Solution**: Keep old column until thoroughly tested (in production)

❌ **Missing indexes**: New table performs poorly  
✅ **Solution**: Add index on FeedbackID immediately

## Success Criteria
✅ New `CustomerFeedbackComments` table created  
✅ All comments migrated successfully  
✅ Row counts match between old and new structures  
✅ Foreign key relationship established with CASCADE  
✅ Index created on FeedbackID  
✅ Old Comments column removed  
✅ Queries run faster (measure with SET STATISTICS TIME ON)  
✅ Migration committed to source control

## Troubleshooting
- **Foreign key violations**: Ensure FeedbackID exists in parent table
- **Slow migration**: Use batching for very large tables
- **Orphaned records**: Verify CASCADE behavior before dropping column
- **Disk space**: Ensure enough space for both old and new columns during migration

## Production Deployment Strategy
For very large tables in production:

1. **Phase 1**: Add new table (no data migration yet)
2. **Phase 2**: Application writes to both tables
3. **Phase 3**: Background job migrates old data
4. **Phase 4**: Verify data is in sync
5. **Phase 5**: Application reads from new table only
6. **Phase 6**: Drop old column after monitoring period

## Real-World Applications
- **Blog Systems**: Separate post content from metadata
- **Document Management**: Split large attachments from records
- **Audit Logs**: Move detailed logs to separate tables
- **Social Media**: Separate post content from engagement metrics

## Advanced Challenge (Optional)
1. Add a `CommentLength` computed column to the main table for quick filtering
2. Create a stored procedure that efficiently fetches feedback with optional comments
3. Implement row-level compression on the comments table
4. Set up partitioning on the comments table by date

## Next Steps
Excellent work on table refactoring! Move on to **Operations Quest 3** to learn about merging and managing pending database changes!
