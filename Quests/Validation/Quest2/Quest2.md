**RUN THE SQL SCRIPT FIRST TO CREATE THE NEEDED QUEST ITEMS**

# Validation Quest 2: Production Deployment Validation with Flyway Check

**Difficulty:** ⭐⭐⭐⭐ Advanced  
**Time:** 35-45 minutes  
**Prerequisites:** Completed Validation Quest 1, Access to Azure DevOps pipeline

## Learning Objectives
By completing this quest, you will learn:
- Using Flyway Check reports for pre-deployment validation
- Detecting schema drift before deployment
- Understanding Flyway Check: Changes, Drift, and Code Analysis
- Reading and interpreting deployment reports
- Making go/no-go deployment decisions
- CI/CD pipeline integration best practices

## Scenario
You're about to deploy database changes to **Production**—a critical operation that could impact thousands of users and business operations. Before the deployment, you need to:
- Verify what changes will be applied
- Check for unexpected drift (unauthorized manual changes)
- Ensure no breaking changes will occur
- Review potential risks

Flyway's Check feature provides comprehensive reports to validate deployments before they happen, preventing costly production issues.

## Your Mission
Trigger a Flyway deployment pipeline, review the generated Check reports, and make an informed decision about whether to proceed with the deployment.

## Objective
1. Navigate to Azure DevOps and locate the Flyway pipeline
2. Trigger a deployment that generates Check reports
3. Review the **Changes Report** (what will be deployed)
4. Review the **Drift Report** (what's different from expected state)
5. Analyze any warnings or errors
6. Make a go/no-go decision
7. Document your findings

## Understanding Flyway Check

Flyway Check provides three types of reports:

### 1. **Changes Report**
- Shows what changes will be applied
- Highlights new migrations vs previously applied
- Identifies potential breaking changes
- Helps communicate impact to stakeholders

### 2. **Drift Report**
- Detects unauthorized changes in target database
- Compares actual schema to expected state
- Shows objects that exist but aren't in migrations
- Identifies modified objects

### 3. **Code Analysis Report** (Enterprise)
- Static analysis of SQL code
- Identifies code smells and anti-patterns
- Performance issue detection
- Security vulnerability scanning

## Steps

### Step 1: Access Azure DevOps Pipeline

1. **Open Azure DevOps**:
   - Navigate to your Azure DevOps project
   - Go to **Pipelines** section

2. **Locate Flyway Pipeline**:
   - Find the pipeline named "Flyway-AutoPilot" or similar
   - Review recent run history

3. **Check Pipeline Configuration**:
   - Verify it includes Flyway Check stages
   - Look for artifact uploads (reports)

### Step 2: Trigger a Check Run

1. **Start the Pipeline**:
   - Click "Run pipeline"
   - Select the branch with your changes
   - Choose the target environment (Test or Prod)

2. **Monitor Execution**:
   - Watch the pipeline stages execute
   - Look for "Flyway Check" stages
   - Wait for completion

### Step 3: Review Changes Report

1. **Download the Report**:
   - Navigate to the pipeline run
   - Go to **Artifacts** or **Reports** section
   - Download **"Changes Report"** for your environment

2. **Analyze the Report**:
```
Changes Report - Production Environment
===========================================

Pending Migrations: 5

V013__Partition_MaintenanceLog_by_year.sql
  - Impact: MEDIUM
  - Type: ALTER TABLE, CREATE PARTITION FUNCTION
  - Risk: Data movement, downtime possible
  - Rollback: Manual required

V014__Add_flight_duration_computed_column.sql
  - Impact: LOW
  - Type: ALTER TABLE, CREATE INDEX
  - Risk: Minimal, quick operation
  - Rollback: DROP COLUMN, DROP INDEX

V015__Add_cascade_delete_to_order_audit_log.sql
  - Impact: HIGH
  - Type: ALTER TABLE (Foreign Key)
  - Risk: Cascading deletes enabled!
  - Rollback: Manual constraint recreation

... more migrations ...

Total Objects to be Created: 12
Total Objects to be Modified: 8
Estimated Duration: 15-20 minutes
```

3. **Key Things to Check**:
   - ✅ Are all expected migrations listed?
   - ✅ Do the changes match what you intended to deploy?
   - ❌ Any unexpected migrations?
   - ❌ High-risk operations (table drops, large data moves)?

### Step 4: Review Drift Report

1. **Download Drift Report**:
   - From the same artifacts location
   - Download **"Drift Report"**

2. **Analyze Drift**:
```
Drift Detection Report - Production
=====================================

Drift Detected: YES

Unexpected Objects (not in migrations):
---------------------------------------
1. Schema: Sales
   Object: GetQuarterlyRevenue (Stored Procedure)
   Created: 2024-01-15 14:30:00
   Created By: john.developer
   Status: NOT IN SOURCE CONTROL

2. Schema: Inventory
   Object: IX_Flight_Emergency (Index)
   Created: 2024-01-18 09:15:00
   Created By: dba.admin
   Status: NOT IN SOURCE CONTROL

Modified Objects (differ from migrations):
------------------------------------------
1. Schema: Sales
   Object: CustomerOrdersView (View)
   Last Modified: 2024-01-20 16:45:00
   Modified By: jane.analyst
   Difference: Added WHERE clause filter
   Status: DIFFERS FROM SOURCE

Schema Differences: 3 objects
Data Drift: Not detected (not scanned)
```

3. **Investigate Drift**:
   - **Why does drift exist?** Hotfixes? Manual changes? Testing?
   - **Is it safe to deploy over it?** Or should drift be captured first?
   - **Who made the changes?** Contact them to understand the changes

### Step 5: Decision Making

**Scenario A: Clean Deployment (No Issues)**
```
✅ All migrations are expected
✅ No drift detected
✅ No high-risk operations
✅ Test environment deployment successful
→ Decision: PROCEED with deployment
```

**Scenario B: Drift Detected**
```
❌ Drift detected: Unauthorized stored procedure
⚠️  Changes might be overwritten or cause conflicts
→ Decision: PAUSE deployment
→ Action: Capture drift in new migration first
→ Then: Re-run pipeline
```

**Scenario C: High-Risk Changes**
```
⚠️  Migration includes table partitioning (long operation)
⚠️  Cascading deletes enabled (potential data loss)
✅ No drift
→ Decision: PROCEED with caution
→ Action: Schedule during maintenance window
→ Action: Notify stakeholders
→ Action: Prepare rollback plan
```

**Scenario D: Unexpected Migrations**
```
❌ Migration V020 appears but shouldn't be deployed yet
❌ Feature not complete
→ Decision: ABORT deployment
→ Action: Remove migration from branch
→ Action: Re-deploy without that migration
```

### Step 6: Take Action Based on Report

**If Proceeding:**
1. Click "Continue deployment" in pipeline
2. Monitor the migration execution
3. Verify successful completion
4. Run post-deployment validation queries

**If Pausing:**
1. Cancel/stop the pipeline
2. Address the identified issues
3. Re-run checks after fixes
4. Proceed only when clean

**If Aborting:**
1. Stop the pipeline immediately
2. Document the reasons
3. Notify the team
4. Fix the issues in development
5. Re-submit for deployment later

### Step 7: Document Your Findings

Create a deployment report:

```markdown
# Deployment Review - 2024-01-22

## Environment: Production

## Check Report Summary
- **Changes Report**: 5 pending migrations
- **Drift Report**: 2 objects detected
- **Code Analysis**: No critical issues

## Findings
1. Migration V015 enables cascading deletes - HIGH RISK
2. Drift detected: Emergency index created manually by DBA
3. All migrations tested successfully in Test environment

## Decision: PROCEED with CAUTION

## Actions Taken
1. Captured drift (emergency index) in new migration V018
2. Notified business team about cascading delete behavior
3. Scheduled deployment for maintenance window (2 AM)
4. DBA on standby for monitoring

## Rollback Plan
- V015: Manual FK constraint recreation script prepared
- V013: Partition switch-out script ready
- Full database backup taken pre-deployment

## Sign-off
- Developer: [Your Name]
- DBA: [DBA Name]
- Manager: [Manager Name]
```

## Hints
- **Always Check Test First**: Run against Test environment before Prod
- **Understand Drift**: Drift isn't always bad, but must be understood
- **Risk Assessment**: Weigh risk vs business value
- **Communication**: Keep stakeholders informed
- **Rollback Ready**: Always have a rollback plan

## Key Concepts Learned
- **Pre-Deployment Validation**: Catching issues before production
- **Drift Detection**: Identifying unauthorized changes
- **Risk Assessment**: Evaluating deployment safety
- **CI/CD Integration**: Automated checks in pipelines
- **Decision Making**: Go/no-go based on data

## Common Scenarios and Responses

### Scenario: "Drift includes a hotfix that worked"
**Response**: Capture the hotfix in a new migration, then deploy
```sql
-- Create retroactive migration
-- V018__Capture_emergency_hotfix.sql
-- (contains the hotfix that was manually applied)
```

### Scenario: "Changes break backward compatibility"
**Response**: Consider a staged rollout
1. Deploy new schema alongside old
2. Update application to use new schema
3. Remove old schema in future migration

### Scenario: "Report shows long-running migration"
**Response**: Schedule during maintenance window
- Notify users of downtime
- Set up monitoring
- Have DBA available

### Scenario: "Code analysis shows SQL injection risk"
**Response**: Fix the code before deploying
- Rewrite stored procedure with parameterization
- Update migration
- Re-run checks

## Real-World Best Practices

### Deployment Checklist:
- [ ] Check reports reviewed and approved
- [ ] Drift investigated and resolved
- [ ] High-risk changes identified and mitigated
- [ ] Test environment deployment successful
- [ ] Rollback plan documented
- [ ] Stakeholders notified
- [ ] Backup taken
- [ ] Monitoring in place

### Red Flags (Stop Deployment):
🚨 Unknown migrations in pipeline
🚨 Drift that would be overwritten
🚨 Critical errors in code analysis
🚨 Test environment deployment failed
🚨 No rollback plan for high-risk changes
🚨 Unauthorized object drops detected

## Success Criteria
✅ Pipeline executed and Check reports generated  
✅ Changes report reviewed and all migrations identified  
✅ Drift report analyzed and drift investigated  
✅ Informed go/no-go decision made  
✅ Decision documented with reasoning  
✅ If deployed: Post-deployment validation completed  
✅ If aborted: Issues documented and assigned for fixing

## Troubleshooting
- **Reports not generated**: Check pipeline configuration includes Check commands
- **Can't download reports**: Check Azure DevOps artifact permissions
- **Drift false positives**: Configure Flyway to ignore certain objects
- **Reports confusing**: Consult Flyway documentation for report format

## Advanced Topics

### Configuring Flyway Check:
```toml
# flyway.toml
[flyway.check]
  # Generate detailed drift report
  drift = true
  
  # Run code analysis
  code = true
  
  # Fail build on drift
  failOnDrift = true
  
  # Ignore specific schemas
  driftIgnore = ["TempSchema", "TestSchema"]
```

### Automating Decisions:
```yaml
# Azure DevOps pipeline snippet
- script: |
    # Fail if critical drift detected
    if grep -q "CRITICAL" drift-report.txt; then
      echo "Critical drift detected!"
      exit 1
    fi
  displayName: 'Validate Drift Report'
```

## Next Steps
Excellent work on production validation! Move on to **Validation Quest 3** to learn about Flyway callbacks for advanced automation!
