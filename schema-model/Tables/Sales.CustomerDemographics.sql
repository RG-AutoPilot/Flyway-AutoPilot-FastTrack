CREATE TABLE [Sales].[CustomerDemographics]
(
[CustomerTypeID] [nchar] (10) NOT NULL,
[CustomerDesc] [ntext] NULL,
[TestID] [int] NULL
)
GO
ALTER TABLE [Sales].[CustomerDemographics] ADD CONSTRAINT [PK_CustomerDemographics] PRIMARY KEY NONCLUSTERED ([CustomerTypeID])
GO
