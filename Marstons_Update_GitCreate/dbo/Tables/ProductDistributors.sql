CREATE TABLE [dbo].[ProductDistributors] (
    [ID]          INT           IDENTITY (1, 1) NOT NULL,
    [ShortName]   VARCHAR (5)   NOT NULL,
    [Description] VARCHAR (100) NOT NULL,
    CONSTRAINT [PK_ProductDistributors] PRIMARY KEY CLUSTERED ([ID] ASC)
);

