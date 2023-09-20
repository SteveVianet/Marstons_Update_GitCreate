CREATE TABLE [dbo].[SiteStockistCategories] (
    [EDISID]     INT NOT NULL,
    [CategoryID] INT NOT NULL,
    [IsTied]     BIT NOT NULL,
    [IsStockist] BIT NOT NULL,
    CONSTRAINT [PK_SiteStockistCategories] PRIMARY KEY CLUSTERED ([EDISID] ASC, [CategoryID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_SiteStockistCategories_StockistCategories] FOREIGN KEY ([CategoryID]) REFERENCES [dbo].[StockistCategories] ([ID])
);

