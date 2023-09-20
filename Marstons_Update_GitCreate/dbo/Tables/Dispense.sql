CREATE TABLE [dbo].[Dispense] (
    [EDISID]         INT        NOT NULL,
    [Date]           DATE       NOT NULL,
    [TradingDate]    DATE       NOT NULL,
    [Shift]          INT        NOT NULL,
    [Pump]           INT        NOT NULL,
    [Product]        INT        NOT NULL,
    [Location]       INT        NOT NULL,
    [Quantity]       FLOAT (53) NOT NULL,
    [LiquidType]     INT        NOT NULL,
    [QuantityBackup] FLOAT (53) NULL,
    CONSTRAINT [PK_Dispense] PRIMARY KEY CLUSTERED ([EDISID] ASC, [Date] ASC, [Shift] ASC, [Pump] ASC),
    CONSTRAINT [FK_Dispense_LiquidTypes] FOREIGN KEY ([LiquidType]) REFERENCES [dbo].[LiquidTypes] ([ID]),
    CONSTRAINT [FK_Dispense_Locations] FOREIGN KEY ([Location]) REFERENCES [dbo].[Locations] ([ID]),
    CONSTRAINT [FK_Dispense_Products] FOREIGN KEY ([Product]) REFERENCES [dbo].[Products] ([ID]),
    CONSTRAINT [FK_Dispense_Sites] FOREIGN KEY ([EDISID]) REFERENCES [dbo].[Sites] ([EDISID])
);

