CREATE TABLE [dbo].[PeriodCacheTradingDispenseWeekly] (
    [EDISID]         INT        NOT NULL,
    [WeekCommencing] DATE       NOT NULL,
    [Pump]           INT        NOT NULL,
    [LocationID]     INT        NULL,
    [ProductID]      INT        NOT NULL,
    [Volume]         FLOAT (53) NULL,
    [WastedVolume]   FLOAT (53) NULL
);


GO
CREATE NONCLUSTERED INDEX [IX_PeriodCacheWeekly_EDISID]
    ON [dbo].[PeriodCacheTradingDispenseWeekly]([EDISID] ASC, [WeekCommencing] ASC);

