CREATE TABLE [dbo].[ProductPrices] (
    [EDISID]    INT           NOT NULL,
    [ProductID] INT           NOT NULL,
    [Price]     MONEY         NOT NULL,
    [ValidFrom] SMALLDATETIME NOT NULL,
    [ValidTo]   SMALLDATETIME NULL,
    CONSTRAINT [PK_ProductPrices] PRIMARY KEY CLUSTERED ([EDISID] ASC, [ProductID] ASC, [ValidFrom] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_ProductPrices_Products] FOREIGN KEY ([ProductID]) REFERENCES [dbo].[Products] ([ID]) ON DELETE CASCADE,
    CONSTRAINT [FK_ProductPrices_Sites] FOREIGN KEY ([EDISID]) REFERENCES [dbo].[Sites] ([EDISID]) ON DELETE CASCADE
);

