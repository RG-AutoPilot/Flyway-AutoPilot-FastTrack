**RUN THE SQL SCRIPT FIRST TO CREATE THE NEEDED QUEST ITEMS**

# Developer Quest - Schema Normalization

**Difficulty:** Intermediate  
**Time:** 35-45 minutes  
**Prerequisites:** Understanding of Flyway migrations, SQL DDL

## Learning Objectives
By completing this quest, you will learn:
- Database normalization principles (3NF)
- How to refactor existing schemas safely
- Managing data migration during schema changes
- Handling foreign key relationships
- Multi-step migration strategies

## Scenario
Your `Customers.Customer` table has grown organically over time and now contains denormalized data. Each customer has `Phone` and `Address` fields stored directly in the customer record. However, customers often have multiple phone numbers (home, work, mobile) and multiple addresses (billing, shipping), but the current design only supports one of each.

The operations team has received complaints about data limitation and wants you to normalize this schema to support multiple phones and addresses per customer.

## Your Mission
Refactor the `Customers.Customer` table to support multiple phone numbers and addresses by creating separate related tables.

## Objective
1. Create two new normalized tables:
   - `Customers.CustomerPhone` (supports multiple phones per customer)
   - `Customers.CustomerAddress` (supports multiple addresses per customer)
2. Migrate existing data from `Customers.Customer` to the new tables
3. Establish proper foreign key relationships
4. Remove the denormalized columns from the original table
5. Ensure data integrity throughout the process

## Database Design

### Current Schema (Denormalized):
```sql
Customers.Customer
├── CustomerID (PK)
├── FirstName
├── LastName
├── Email
├── Phone          -- Only one phone!
└── Address        -- Only one address!
```

### Target Schema (Normalized):
```sql
Customers.Customer
├── CustomerID (PK)
├── FirstName
├── LastName
└── Email

Customers.CustomerPhone
├── PhoneID (PK)
├── CustomerID (FK) → Customers.Customer
├── PhoneType (e.g., 'Home', 'Work', 'Mobile')
└── Phone

Customers.CustomerAddress
├── AddressID (PK)
├── CustomerID (FK) → Customers.Customer
├── AddressType (e.g., 'Billing', 'Shipping')
└── Address
```

## Steps

### Step 1: Create the New Tables
```sql
-- Create CustomerPhone table
CREATE TABLE Customers.CustomerPhone (
    PhoneID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID INT NOT NULL,
    PhoneType NVARCHAR(20) NOT NULL DEFAULT 'Primary',
    Phone NVARCHAR(20) NOT NULL,
    CONSTRAINT FK_CustomerPhone_Customer 
        FOREIGN KEY (CustomerID) REFERENCES Customers.Customer(CustomerID)
);

-- Create CustomerAddress table
CREATE TABLE Customers.CustomerAddress (
    AddressID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID INT NOT NULL,
    AddressType NVARCHAR(20) NOT NULL DEFAULT 'Primary',
    Address NVARCHAR(200) NOT NULL,
    CONSTRAINT FK_CustomerAddress_Customer 
        FOREIGN KEY (CustomerID) REFERENCES Customers.Customer(CustomerID)
);
```

### Step 2: Migrate Existing Data
```sql
-- Migrate phone data
INSERT INTO Customers.CustomerPhone (CustomerID, PhoneType, Phone)
SELECT 
    CustomerID,
    'Primary' AS PhoneType,
    Phone
FROM Customers.Customer
WHERE Phone IS NOT NULL;

-- Migrate address data
INSERT INTO Customers.CustomerAddress (CustomerID, AddressType, Address)
SELECT 
    CustomerID,
    'Primary' AS AddressType,
    Address
FROM Customers.Customer
WHERE Address IS NOT NULL;
```

### Step 3: Verify Data Migration
```sql
-- Check that all phones migrated
SELECT 
    'Customers.Customer' AS Source,
    COUNT(*) AS Count
FROM Customers.Customer
WHERE Phone IS NOT NULL
UNION ALL
SELECT 
    'Customers.CustomerPhone' AS Source,
    COUNT(*) AS Count
FROM Customers.CustomerPhone;

-- Check that all addresses migrated
SELECT 
    'Customers.Customer' AS Source,
    COUNT(*) AS Count
FROM Customers.Customer
WHERE Address IS NOT NULL
UNION ALL
SELECT 
    'Customers.CustomerAddress' AS Source,
    COUNT(*) AS Count
FROM Customers.CustomerAddress;
```

### Step 4: Drop Old Columns
```sql
-- Only after verifying data migration!
ALTER TABLE Customers.Customer
DROP COLUMN Phone, Address;
```

### Step 5: Create Flyway Migrations

**Option A: Single Migration (Simpler)**
Create one versioned migration with all steps:
```
V006__Normalize_customer_contact_info.sql
```

**Option B: Multiple Migrations (Safer)**
Break into separate migrations:
```
V006__Create_CustomerPhone_table.sql
V007__Create_CustomerAddress_table.sql
V008__Migrate_phone_data.sql
V009__Migrate_address_data.sql
V010__Remove_denormalized_columns.sql
```

**Recommended**: Option B for production, as it allows rollback at each step

### Step 6: Commit and Deploy
1. Generate migrations using Flyway Desktop
2. Test in Dev environment
3. Commit to source control
4. Deploy through CI/CD pipeline

## Hints
- **Always Migrate Data Before Dropping Columns**: Losing data is NOT an option!
- **Test Thoroughly**: Verify row counts match before and after migration
- **Foreign Keys First**: Create relationships before migrating data
- **Use Transactions**: Wrap migration in transactions for safety (in prod)
- **Backup**: Always backup production before major schema changes

## Key Concepts Learned
- **Normalization**: Organizing data to reduce redundancy
- **3NF (Third Normal Form)**: Eliminating transitive dependencies
- **Foreign Keys**: Enforcing referential integrity
- **Data Migration**: Moving data during schema changes
- **Multi-Step Migrations**: Breaking complex changes into safe steps

## Best Practices for Schema Refactoring

### ✅ DO:
- Plan the entire migration before starting
- Test with realistic data volumes
- Verify data integrity at each step
- Keep old columns until new system is proven
- Document the migration process

### ❌ DON'T:
- Drop columns before migrating data
- Skip data verification steps
- Deploy untested migrations to production
- Ignore foreign key constraints
- Rush the process

## Common Pitfalls to Avoid
❌ **Dropping columns too early**: Results in data loss  
✅ **Solution**: Always migrate data first, verify, then drop

❌ **Missing foreign keys**: Allows invalid data  
✅ **Solution**: Create constraints before or with data migration

❌ **Ignoring NULL values**: Migration fails on null data  
✅ **Solution**: Use WHERE clauses to handle NULL appropriately

## Success Criteria
✅ Two new tables `CustomerPhone` and `CustomerAddress` exist  
✅ All existing phone numbers migrated to new table  
✅ All existing addresses migrated to new table  
✅ Foreign key relationships established and enforced  
✅ Old columns removed from `Customers.Customer`  
✅ Data counts match before and after migration  
✅ All migrations committed to source control  
✅ No data loss occurred

## Troubleshooting
- **Foreign key violations**: Ensure Customer records exist before inserting related data
- **NULL constraint violations**: Filter out NULL values during migration
- **Duplicate data**: Check for existing records before inserting
- **Column drop fails**: Verify no dependencies exist (views, procedures)

## Testing Your Migration
```sql
-- Test 1: Add a new customer with multiple phones
INSERT INTO Customers.Customer (CustomerID, FirstName, LastName, Email)
VALUES (9999, 'Test', 'User', 'test@example.com');

INSERT INTO Customers.CustomerPhone (CustomerID, PhoneType, Phone)
VALUES 
    (9999, 'Home', '555-1111'),
    (9999, 'Work', '555-2222'),
    (9999, 'Mobile', '555-3333');

-- Test 2: Query to see all phones for a customer
SELECT c.FirstName, c.LastName, p.PhoneType, p.Phone
FROM Customers.Customer c
LEFT JOIN Customers.CustomerPhone p ON c.CustomerID = p.CustomerID
WHERE c.CustomerID = 9999;

-- Test 3: Verify foreign key constraint
-- This should fail:
INSERT INTO Customers.CustomerPhone (CustomerID, PhoneType, Phone)
VALUES (99999, 'Home', '555-9999');  -- Non-existent CustomerID
```

## Real-World Applications
- **E-commerce**: Supporting multiple shipping addresses
- **CRM Systems**: Managing multiple contact methods per customer
- **Healthcare**: Storing multiple emergency contacts
- **Enterprise**: Handling complex organizational relationships

## Advanced Challenge (Optional)
1. Add a `IsPrimary` bit column to both new tables
2. Create a trigger to ensure only one primary phone/address per customer
3. Create views that replicate the old denormalized structure for backward compatibility

## Next Steps
Great work on normalizing the schema! Explore other Operations quests to learn about safe data migration strategies!
