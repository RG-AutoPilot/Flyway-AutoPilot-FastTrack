SET NUMERIC_ROUNDABORT OFF
GO
SET ANSI_PADDING, ANSI_WARNINGS, CONCAT_NULL_YIELDS_NULL, ARITHABORT, QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
PRINT N'Dropping [dbo].[getAddress]'
GO
DROP PROCEDURE [dbo].[getAddress]
GO
PRINT N'Dropping [dbo].[AddressBook]'
GO
DROP TABLE [dbo].[AddressBook]
GO
PRINT N'Altering [Sales].[CustomerDemographics]'
GO
ALTER TABLE [Sales].[CustomerDemographics] DROP
COLUMN [TestID]
GO

