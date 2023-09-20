CREATE TABLE [dbo].[Stock] (
    [MasterDateID]   INT        NOT NULL,
    [ProductID]      INT        NOT NULL,
    [Quantity]       FLOAT (53) NOT NULL,
    [Hour]           INT        DEFAULT (0) NOT NULL,
    [BeforeDelivery] BIT        DEFAULT (0) NOT NULL,
    CONSTRAINT [PK_Stock] PRIMARY KEY CLUSTERED ([MasterDateID] ASC, [ProductID] ASC),
    CONSTRAINT [FK_Stock_MasterDates] FOREIGN KEY ([MasterDateID]) REFERENCES [dbo].[MasterDates] ([ID]),
    CONSTRAINT [FK_Stock_Products] FOREIGN KEY ([ProductID]) REFERENCES [dbo].[Products] ([ID])
);

