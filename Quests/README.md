# Flyway AutoPilot FastTrack - Quest Guide

Welcome to the Flyway AutoPilot FastTrack quest system! This comprehensive learning program helps you master Flyway through hands-on, practical exercises organized by role and focus area.

## 🎯 Quest Organization

The quests are organized into **three categories** based on different aspects of Flyway usage:

### 👨‍💻 Developer Quests
**Focus:** Using Flyway Desktop to create and manage database objects and schema changes  
**Tools:** Flyway Desktop, SQL Server Management Studio / Azure Data Studio  
**Skills:** Creating migrations, modifying schemas, managing database objects

### 🔧 Operations Quests
**Focus:** Audits, reports, approvals, pipelines, and deployment validation  
**Tools:** Azure DevOps, Flyway CLI, Flyway Check  
**Skills:** CI/CD pipelines, deployment validation, drift detection, approvals

### 📦 Other Quests
**Focus:** Advanced automation and specialized Flyway features  
**Tools:** Various Flyway features  
**Skills:** Callbacks, advanced automation

---

## 📚 Quest Catalog

### 👨‍💻 Developer Quests

These quests focus on using Flyway Desktop to create database objects and manage schema changes. Perfect for developers who need to version control their database work.

#### Quest 1: Your First Migration
**Time:** 15-20 minutes | **Difficulty:** Beginner  
**Learn:** Create your first Flyway migration, understand versioned migrations, and learn the basic workflow.  
**Skills:** CREATE TABLE, migration generation, schema history tracking

#### Quest 2: Modifying Existing Tables
**Time:** 15-20 minutes | **Difficulty:** Beginner  
**Learn:** Safely modify existing database schemas and manage schema evolution.  
**Skills:** ALTER TABLE, backward compatibility, nullable columns

#### Quest 3: Working with Database Views
**Time:** 20-25 minutes | **Difficulty:** Beginner  
**Learn:** Create and modify views, understand repeatable vs versioned migrations.  
**Skills:** CREATE VIEW, ALTER VIEW, repeatable migrations (R__)

#### Quest 4: Fixing Broken Dependencies
**Time:** 20-30 minutes | **Difficulty:** Beginner-Intermediate  
**Learn:** Identify and fix broken database object dependencies.  
**Skills:** Object dependencies, stored procedures, system catalog queries

#### Quest 5: Managing Static Data
**Time:** 25-30 minutes | **Difficulty:** Intermediate  
**Learn:** Version control reference data and manage static data deployments.  
**Skills:** Static data tracking, skipExecutingMigrations, idempotent scripts

#### Quest 6: Schema Normalization
**Time:** 35-45 minutes | **Difficulty:** Intermediate  
**Learn:** Normalize database schemas and safely refactor existing tables.  
**Skills:** Database normalization, foreign keys, data migration, multi-step migrations

#### Quest 7: Large Table Refactoring
**Time:** 30-40 minutes | **Difficulty:** Intermediate  
**Learn:** Split large tables for better performance and manageability.  
**Skills:** Vertical partitioning, 1:1 relationships, performance optimization

#### Quest 8: Merging Pending Changes
**Time:** 30-40 minutes | **Difficulty:** Intermediate  
**Learn:** Manage concurrent development and selectively deploy schema changes.  
**Skills:** Selective migration, schema filtering, concurrent development

#### Quest 9: Table Partitioning
**Time:** 35-45 minutes | **Difficulty:** Intermediate-Advanced  
**Learn:** Implement table partitioning for large datasets.  
**Skills:** Partition functions, partition schemes, performance tuning

#### Quest 10: Computed Columns and Indexes
**Time:** 30-40 minutes | **Difficulty:** Intermediate-Advanced  
**Learn:** Add computed columns and optimize queries with indexes.  
**Skills:** Computed columns (PERSISTED), covering indexes, query optimization

#### Quest 11: Cascading Deletes
**Time:** 25-35 minutes | **Difficulty:** Intermediate  
**Learn:** Manage referential integrity with cascading operations.  
**Skills:** Foreign key constraints, CASCADE, SET NULL, referential integrity

#### Quest 12: Unique Constraints
**Time:** 25-30 minutes | **Difficulty:** Intermediate  
**Learn:** Enforce uniqueness and prevent duplicate data.  
**Skills:** Unique constraints, multi-column uniqueness, data validation

#### Quest 13: Check Constraints
**Time:** 30-40 minutes | **Difficulty:** Advanced  
**Learn:** Implement complex data validation rules at the database level.  
**Skills:** CHECK constraints, data validation, business rule enforcement

#### Quest 14: Complex Stored Procedures
**Time:** 45-60 minutes | **Difficulty:** Advanced  
**Learn:** Create enterprise-grade stored procedures and functions.  
**Skills:** Stored procedures, error handling, transactions, scalar/table-valued functions

---

### 🔧 Operations Quests

These quests focus on the operational aspects of Flyway: pipelines, reports, audits, and deployment validation. Essential for DBAs and DevOps engineers.

#### Quest 1: Production Deployment Validation
**Time:** 35-45 minutes | **Difficulty:** Intermediate  
**Learn:** Use Flyway Check reports to validate deployments before production.  
**Skills:** Flyway Check, drift detection, Changes reports, CI/CD validation, pipeline management

**Key Topics:**
- Triggering Flyway pipelines in Azure DevOps
- Reading and interpreting Check reports
- Detecting schema drift
- Making go/no-go deployment decisions
- Reviewing changes before they're deployed
- Understanding code analysis reports

---

### 📦 Other Quests

These quests cover advanced Flyway features and automation that don't fit neatly into developer or operations categories.

#### Quest 1: Flyway Callbacks
**Time:** 40-50 minutes | **Difficulty:** Advanced  
**Learn:** Automate operations with Flyway's callback lifecycle.  
**Skills:** Callback events, afterClean, beforeMigrate, automation

**Key Topics:**
- Understanding callback lifecycle events
- Creating afterClean callbacks
- Automating pre/post migration tasks
- Implementing validation checks

---

## 🚀 Getting Started

### Prerequisites
- **Flyway Desktop** installed and configured
- **Sample database** set up (see main README)
- **Azure DevOps** access (for Operations quests)
- **SQL Server Management Studio** or Azure Data Studio

### Recommended Approach

**For Developers:**
1. Start with Developer Quest 1 and work through sequentially
2. Focus on learning Flyway Desktop workflows
3. Practice creating and managing migrations
4. Apply skills to your own projects

**For Operations/DBAs:**
1. Review Developer Quests 1-5 for Flyway basics
2. Focus on Operations Quest 1 for pipeline and deployment validation
3. Explore Other Quest 1 for advanced automation
4. Integrate learnings into your CI/CD pipelines

**For Full-Stack Teams:**
1. Developers complete Developer quests
2. DevOps/DBAs complete Operations quests
3. Share knowledge across the team
4. Collaborate on CI/CD pipeline design

### Before Each Quest

1. Read the quest objectives and scenario
2. Run the provided SQL script to set up test data (if applicable)
3. Follow the steps carefully
4. Test your solutions thoroughly
5. Review the success criteria

---

## 📊 Quest Structure

Each quest follows a consistent structure:

1. **Header**: Difficulty, time estimate, prerequisites
2. **Learning Objectives**: What you'll learn
3. **Scenario**: Real-world context
4. **Your Mission**: Clear goal
5. **Objective**: Specific tasks
6. **Steps**: Detailed walkthrough
7. **Hints**: Helpful tips
8. **Key Concepts**: Summary of learnings
9. **Common Pitfalls**: What to avoid
10. **Success Criteria**: How to validate completion
11. **Troubleshooting**: Common issues and solutions
12. **Real-World Applications**: Where to use these skills
13. **Advanced Challenge**: Optional extensions (where applicable)
14. **Next Steps**: What's next

---

## 💡 Tips for Success

### Do's ✅
- Complete quests in order within each category
- Test thoroughly before moving to the next quest
- Read the "Key Concepts Learned" sections
- Try the advanced challenges when available
- Document your learnings
- Ask questions when stuck

### Don'ts ❌
- Don't skip the setup scripts
- Don't rush through without understanding
- Don't skip testing your solutions
- Don't ignore the troubleshooting sections
- Don't skip the hints - they're valuable!

---

## 📈 Track Your Progress

Create a checklist to track your journey:

### 👨‍💻 Developer Quests
- [ ] Quest 1: Your First Migration
- [ ] Quest 2: Modifying Existing Tables
- [ ] Quest 3: Working with Database Views
- [ ] Quest 4: Fixing Broken Dependencies
- [ ] Quest 5: Managing Static Data
- [ ] Quest 6: Schema Normalization
- [ ] Quest 7: Large Table Refactoring
- [ ] Quest 8: Merging Pending Changes
- [ ] Quest 9: Table Partitioning
- [ ] Quest 10: Computed Columns and Indexes
- [ ] Quest 11: Cascading Deletes
- [ ] Quest 12: Unique Constraints
- [ ] Quest 13: Check Constraints
- [ ] Quest 14: Complex Stored Procedures

### 🔧 Operations Quests
- [ ] Quest 1: Production Deployment Validation

### 📦 Other Quests
- [ ] Quest 1: Flyway Callbacks

---

## 🎓 Skills by Category

### Developer Skills
After completing Developer quests, you'll be able to:
- ✅ Create and manage Flyway migrations
- ✅ Modify database schemas safely
- ✅ Work with views, procedures, and functions
- ✅ Manage object dependencies
- ✅ Version control static/reference data
- ✅ Normalize and refactor schemas
- ✅ Optimize database performance
- ✅ Implement data integrity constraints

### Operations Skills
After completing Operations quests, you'll be able to:
- ✅ Set up and manage Flyway pipelines
- ✅ Generate and interpret Check reports
- ✅ Detect and handle schema drift
- ✅ Validate deployments before production
- ✅ Make informed go/no-go decisions
- ✅ Integrate Flyway into CI/CD workflows

### Advanced Skills
After completing Other quests, you'll be able to:
- ✅ Implement Flyway callbacks
- ✅ Automate pre/post migration tasks
- ✅ Create custom validation checks
- ✅ Extend Flyway functionality

---

## 🆘 Getting Help

If you get stuck:

1. Review the **Hints** section in the quest
2. Check the **Troubleshooting** section
3. Review the **Key Concepts** to ensure understanding
4. Consult [Flyway Documentation](https://documentation.red-gate.com/flyway)
5. Ask in your team's communication channels

---

## 📞 Feedback

Have suggestions for improving the quests? Found an issue?
- Open an issue in the repository
- Submit a pull request
- Contact the maintainers

---

**Happy Learning!** 🚀

*Remember: Mastering Flyway takes practice. These quests provide the foundation - your real-world experience will build expertise!*
