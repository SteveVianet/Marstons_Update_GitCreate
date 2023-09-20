CREATE TABLE [dbo].[PeriodCacheQuality] (
    [EDISID]            INT        NOT NULL,
    [TradingDay]        DATETIME   NOT NULL,
    [Pump]              INT        NOT NULL,
    [ProductID]         INT        NOT NULL,
    [LocationID]        INT        NOT NULL,
    [Quantity]          FLOAT (53) NOT NULL,
    [QuantityInSpec]    FLOAT (53) NOT NULL,
    [QuantityInAmber]   FLOAT (53) NOT NULL,
    [QuantityOutOfSpec] FLOAT (53) NOT NULL,
    [AverageFlowRate]   FLOAT (53) NOT NULL,
    CONSTRAINT [PK_PeriodCacheQuality] PRIMARY KEY CLUSTERED ([EDISID] ASC, [TradingDay] ASC, [Pump] ASC, [ProductID] ASC, [LocationID] ASC)
);

