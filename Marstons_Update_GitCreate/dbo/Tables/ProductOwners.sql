CREATE TABLE [dbo].[ProductOwners] (
    [ID]   INT           IDENTITY (1, 1) NOT NULL,
    [Name] VARCHAR (255) NOT NULL,
    CONSTRAINT [PK_ProductOwners] PRIMARY KEY CLUSTERED ([ID] ASC)
);

