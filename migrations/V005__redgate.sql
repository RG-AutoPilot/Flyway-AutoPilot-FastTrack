SET NUMERIC_ROUNDABORT OFF
GO
SET ANSI_PADDING, ANSI_WARNINGS, CONCAT_NULL_YIELDS_NULL, ARITHABORT, QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
PRINT N'Creating [dbo].[AddressBook]'
GO
CREATE TABLE [dbo].[AddressBook]
(
[FirstName] [nvarchar] (24) NULL,
[LastName] [nvarchar] (24) NULL,
[Age] [int] NULL
)
GO
PRINT N'Creating [dbo].[getAddress]'
GO
--SET QUOTED_IDENTIFIER ON|OFF
--SET ANSI_NULLS ON|OFF
--GO
CREATE PROCEDURE [dbo].[getAddress]
    @parameter_name AS INT
-- WITH ENCRYPTION, RECOMPILE, EXECUTE AS CALLER|SELF|OWNER| 'user_name'
AS
BEGIN
    SELECT * FROM dbo.AddressBook
END
GO
PRINT N'Altering [Sales].[CustomerDemographics]'
GO
ALTER TABLE [Sales].[CustomerDemographics] ADD
[TestID] [int] NULL
GO

