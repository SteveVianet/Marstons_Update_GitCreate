CREATE TABLE [dbo].[CallSiteStocks] (
    [CallID]        INT          NOT NULL,
    [Product]       VARCHAR (50) NOT NULL,
    [Size]          VARCHAR (50) NOT NULL,
    [FullQuantity]  INT          NOT NULL,
    [EmptyQuantity] INT          NOT NULL,
    CONSTRAINT [PK_CallSiteStocks] PRIMARY KEY CLUSTERED ([CallID] ASC, [Product] ASC, [Size] ASC),
    FOREIGN KEY ([CallID]) REFERENCES [dbo].[Calls] ([ID])
);

