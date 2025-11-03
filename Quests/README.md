# Flyway AutoPilot FastTrack - Quest Guide

Welcome to the Flyway AutoPilot FastTrack quest system! Choose quests based on what you want to learn - each quest is self-contained and focuses on a specific topic.

## 🎯 Quest Categories

### 👨‍💻 Developer Quests
**Focus:** Using Flyway Desktop to create and manage database objects and schema changes

### 🔧 Operations Quests  
**Focus:** Audits, reports, approvals, pipelines, and deployment validation

### 📦 Other Quests
**Focus:** Advanced automation and specialized Flyway features

---

## 📚 Available Quests

### 👨‍💻 Developer Quests

#### 🟢 First Migration
**What you'll learn:** Create your first Flyway migration and understand the basics  
**Time:** 15-20 minutes | **Difficulty:** Beginner  
**Prerequisites:** Flyway Desktop installed, sample database connected  
**Topics:** Versioned migrations, schema history, Flyway Desktop workflow

Create a simple table migration to learn the fundamentals of Flyway version control.

---

#### 🟢 Static Data
**What you'll learn:** Version control reference and lookup data  
**Time:** 25-30 minutes | **Difficulty:** Intermediate  
**Prerequisites:** Flyway Desktop installed, basic understanding of migrations  
**Topics:** Static data tracking, skipExecutingMigrations, idempotent scripts

Learn how to capture and deploy configuration data alongside your schema changes.

---

#### 🟡 Schema Normalization
**What you'll learn:** Refactor schemas to eliminate redundancy  
**Time:** 35-45 minutes | **Difficulty:** Intermediate  
**Prerequisites:** Understanding of Flyway migrations, SQL DDL  
**Topics:** Database normalization, foreign keys, data migration, multi-step changes

Practice normalizing denormalized schemas while maintaining data integrity.

---

#### 🟡 Merging Changes
**What you'll learn:** Manage concurrent development and selective deployments  
**Time:** 30-40 minutes | **Difficulty:** Intermediate  
**Prerequisites:** Flyway Desktop, Git branching knowledge  
**Topics:** Selective migration generation, schema filtering, team collaboration

Learn to work with multiple developers making changes simultaneously.

---

#### 🔴 Stored Procedures
**What you'll learn:** Create enterprise-grade stored procedures and functions  
**Time:** 45-60 minutes | **Difficulty:** Advanced  
**Prerequisites:** Flyway Desktop, SQL programming experience  
**Topics:** Stored procedures, error handling, transactions, repeatable migrations

Build complex database logic with proper error handling and transaction management.

---

### 🔧 Operations Quests

#### 🟡 Deployment Validation
**What you'll learn:** Validate deployments before production using Flyway Check  
**Time:** 35-45 minutes | **Difficulty:** Intermediate  
**Prerequisites:** Access to Azure DevOps pipeline, Flyway CLI  
**Topics:** Flyway Check reports, drift detection, CI/CD pipelines, go/no-go decisions

Learn to use Flyway's Check feature to catch issues before they reach production.

---

### 📦 Other Quests

#### 🔴 Callbacks
**What you'll learn:** Automate tasks using Flyway's callback lifecycle  
**Time:** 40-50 minutes | **Difficulty:** Advanced  
**Prerequisites:** Understanding of Flyway lifecycle, basic scripting  
**Topics:** Callback events, afterClean, beforeMigrate, automation

Extend Flyway's functionality with custom automation scripts.

---

## 🚀 Getting Started

### How to Choose a Quest

**Pick by topic, not by order!** Each quest is self-contained:

- **Want to learn basics?** Start with "First Migration"
- **Need to handle reference data?** Try "Static Data"
- **Working with a team?** Check out "Merging Changes"
- **Setting up CI/CD?** Go for "Deployment Validation"
- **Need advanced automation?** Explore "Callbacks"

### Prerequisites

- **Flyway Desktop** installed and configured
- **Sample database** set up (see main README)
- **Azure DevOps** access (for Operations quests only)
- **SQL Server Management Studio** or Azure Data Studio

### Quest Structure

Each quest includes:
- 📋 **Learning Objectives** - What you'll master
- 🎯 **Scenario** - Real-world context
- 📝 **Detailed Steps** - Clear instructions
- 💡 **Code Examples** - Copy-paste ready
- ✅ **Success Criteria** - How to validate
- 🐛 **Troubleshooting** - Common issues
- 🚀 **Advanced Challenges** - Optional extensions

---

## 💡 Tips for Success

### Do's ✅
- Pick quests that match your current needs
- Complete the setup script before starting
- Test thoroughly as you go
- Read the troubleshooting section if stuck
- Try the advanced challenges for deeper learning

### Don'ts ❌
- You don't need to do quests in order
- Don't skip the prerequisites
- Don't rush - take time to understand concepts
- Don't ignore the hints sections

---

## 🎓 Skills by Quest

### Developer Skills

**First Migration**
- Creating versioned migrations
- Using Flyway Desktop
- Understanding schema history

**Static Data**
- Version controlling data
- Managing reference tables
- Environment-specific deployments

**Schema Normalization**
- Database design patterns
- Safe refactoring techniques
- Data migration strategies

**Merging Changes**
- Concurrent development
- Selective deployments
- Team collaboration workflows

**Stored Procedures**
- Complex database logic
- Error handling
- Transaction management

### Operations Skills

**Deployment Validation**
- Pipeline setup
- Check report interpretation
- Drift detection
- Production validation

### Advanced Skills

**Callbacks**
- Lifecycle automation
- Custom validation
- Pre/post migration tasks

---

## 📊 Quest Difficulty Legend

🟢 **Beginner** - New to Flyway  
🟡 **Intermediate** - Comfortable with basics  
🔴 **Advanced** - Experienced with Flyway

---

## 🆘 Getting Help

If you get stuck:

1. Check the **Hints** section in the quest
2. Review the **Troubleshooting** guide
3. Consult [Flyway Documentation](https://documentation.red-gate.com/flyway)
4. Ask in your team's communication channels

---

## 📞 Feedback

Have suggestions? Found an issue?
- Open an issue in the repository
- Submit a pull request
- Contact the maintainers

---

**Happy Learning!** 🚀

*Choose the quest that matches what you want to learn today!*
