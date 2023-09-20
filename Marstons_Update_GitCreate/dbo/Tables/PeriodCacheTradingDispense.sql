CREATE TABLE [dbo].[PeriodCacheTradingDispense] (
    [EDISID]       INT        NOT NULL,
    [TradingDay]   DATE       NOT NULL,
    [Pump]         INT        NOT NULL,
    [LocationID]   INT        NULL,
    [ProductID]    INT        NOT NULL,
    [Volume]       FLOAT (53) NULL,
    [WastedVolume] FLOAT (53) NULL
);


GO
CREATE CLUSTERED INDEX [IX_EDISID_TradingDay]
    ON [dbo].[PeriodCacheTradingDispense]([EDISID] ASC, [TradingDay] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_Period_Site_Pump_Products]
    ON [dbo].[PeriodCacheTradingDispense]([EDISID] ASC, [Pump] ASC, [ProductID] ASC, [TradingDay] ASC)
    INCLUDE([LocationID], [Volume], [WastedVolume]);


GO
CREATE NONCLUSTERED INDEX [missing_index_4856_4855_PeriodCacheTradingDispense]
    ON [dbo].[PeriodCacheTradingDispense]([TradingDay] ASC)
    INCLUDE([EDISID], [Pump], [LocationID], [ProductID], [Volume], [WastedVolume]);

