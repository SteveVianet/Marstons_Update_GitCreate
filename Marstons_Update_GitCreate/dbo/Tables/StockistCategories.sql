CREATE TABLE [dbo].[StockistCategories] (
    [ID]          INT           IDENTITY (1, 1) NOT NULL,
    [Description] VARCHAR (255) NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC) WITH (FILLFACTOR = 90)
);

