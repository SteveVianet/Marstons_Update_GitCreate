CREATE TABLE [dbo].[Sales] (
    [ID]                 INT           IDENTITY (1, 1) NOT NULL,
    [MasterDateID]       INT           NOT NULL,
    [ProductID]          INT           NOT NULL,
    [Quantity]           FLOAT (53)    NOT NULL,
    [SaleIdent]          VARCHAR (255) NULL,
    [SaleTime]           DATETIME      NOT NULL,
    [ProductAlias]       VARCHAR (50)  NULL,
    [External]           BIT           DEFAULT (0) NOT NULL,
    [TradingDate]        DATETIME      NOT NULL,
    [SaleDate]           DATETIME      NOT NULL,
    [EDISID]             INT           NOT NULL,
    [ProductDescription] VARCHAR (50)  NULL,
    [Transaction]        VARCHAR (50)  NULL,
    [Teller]             VARCHAR (50)  NULL,
    CONSTRAINT [PK_Sales] PRIMARY KEY NONCLUSTERED ([ID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Sales_MasterDates] FOREIGN KEY ([MasterDateID]) REFERENCES [dbo].[MasterDates] ([ID]) ON DELETE CASCADE,
    CONSTRAINT [FK_Sales_Products] FOREIGN KEY ([ProductID]) REFERENCES [dbo].[Products] ([ID]) ON DELETE CASCADE,
    CONSTRAINT [FK_Sales_Sites] FOREIGN KEY ([EDISID]) REFERENCES [dbo].[Sites] ([EDISID])
);


GO
CREATE CLUSTERED INDEX [IX_Sales_MasterDateID_ProductID]
    ON [dbo].[Sales]([MasterDateID] ASC, [ProductID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Sales_MasterDateID]
    ON [dbo].[Sales]([MasterDateID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Sales_Date]
    ON [dbo].[Sales]([EDISID] ASC, [SaleDate] ASC, [ProductID] ASC, [External] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_Sales_TradingDate]
    ON [dbo].[Sales]([EDISID] ASC, [TradingDate] ASC, [ProductID] ASC, [External] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_Sales_Product]
    ON [dbo].[Sales]([ProductID] ASC)
    INCLUDE([Quantity], [TradingDate], [EDISID]);


GO
CREATE NONCLUSTERED INDEX [missing_index_408819_408818_Sales]
    ON [dbo].[Sales]([EDISID] ASC, [TradingDate] ASC)
    INCLUDE([ProductID], [Quantity]);


GO
CREATE NONCLUSTERED INDEX [missing_index_408821_408820_Sales]
    ON [dbo].[Sales]([TradingDate] ASC)
    INCLUDE([ProductID], [Quantity], [EDISID]);

