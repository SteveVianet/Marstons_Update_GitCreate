CREATE TABLE [dbo].[DispenseActions] (
    [EDISID]              INT        NOT NULL,
    [StartTime]           DATETIME   NOT NULL,
    [TradingDay]          DATETIME   NOT NULL,
    [Pump]                INT        NOT NULL,
    [Location]            INT        NULL,
    [Product]             INT        NOT NULL,
    [Duration]            FLOAT (53) NULL,
    [AverageTemperature]  FLOAT (53) NULL,
    [MinimumTemperature]  FLOAT (53) NULL,
    [MaximumTemperature]  FLOAT (53) NULL,
    [LiquidType]          INT        NOT NULL,
    [OriginalLiquidType]  INT        NULL,
    [AverageConductivity] INT        NULL,
    [MinimumConductivity] INT        NULL,
    [MaximumConductivity] INT        NULL,
    [Pints]               FLOAT (53) NULL,
    [PintsBackup]         FLOAT (53) NULL,
    [EstimatedDrinks]     FLOAT (53) NULL,
    [IFMLiquidType]       INT        NULL,
    CONSTRAINT [PK_DispenseActions] PRIMARY KEY CLUSTERED ([EDISID] ASC, [StartTime] ASC, [Pump] ASC),
    CONSTRAINT [FK_DispenseActions_Products] FOREIGN KEY ([Product]) REFERENCES [dbo].[Products] ([ID])
);


GO
CREATE NONCLUSTERED INDEX [IX_DispenseActions_EDISID]
    ON [dbo].[DispenseActions]([EDISID] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_DispenseActions_Date]
    ON [dbo].[DispenseActions]([StartTime] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_DispenseActions_TradindDate]
    ON [dbo].[DispenseActions]([TradingDay] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_DispenseActions_All]
    ON [dbo].[DispenseActions]([StartTime] ASC, [TradingDay] ASC, [EDISID] ASC, [Product] ASC, [LiquidType] ASC, [Duration] ASC, [Pump] ASC, [Location] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_DispenseActions_Trading_Yield]
    ON [dbo].[DispenseActions]([EDISID] ASC, [LiquidType] ASC, [TradingDay] ASC)
    INCLUDE([Product], [Pints], [EstimatedDrinks]);


GO
CREATE NONCLUSTERED INDEX [IX_DispenseActions_LiquidType]
    ON [dbo].[DispenseActions]([LiquidType] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_DispenseActions_ProductID]
    ON [dbo].[DispenseActions]([Product] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_DispenseActions_ForQuality]
    ON [dbo].[DispenseActions]([EDISID] ASC, [TradingDay] ASC, [LiquidType] ASC, [Pints] ASC, [AverageTemperature] ASC, [Pump] ASC, [Product] ASC, [Location] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_DispenseActions_EDISID_LiquidType]
    ON [dbo].[DispenseActions]([EDISID] ASC, [LiquidType] ASC)
    INCLUDE([TradingDay], [Pump], [Location], [Product]);


GO
CREATE NONCLUSTERED INDEX [missing_index_715_714_DispenseActions]
    ON [dbo].[DispenseActions]([EDISID] ASC, [Pump] ASC, [TradingDay] ASC, [LiquidType] ASC)
    INCLUDE([StartTime], [Duration], [AverageTemperature], [OriginalLiquidType], [MinimumConductivity], [MaximumConductivity], [Pints]);

