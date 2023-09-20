CREATE TABLE [dbo].[PeriodCacheVariance] (
    [EDISID]                 INT        NOT NULL,
    [WeekCommencing]         DATETIME   NOT NULL,
    [ProductID]              INT        NOT NULL,
    [IsTied]                 BIT        NOT NULL,
    [DeliveredBeforeStock]   FLOAT (53) NULL,
    [DeliveredAfterStock]    FLOAT (53) NULL,
    [Delivered]              FLOAT (53) NOT NULL,
    [Dispensed]              FLOAT (53) NOT NULL,
    [Variance]               FLOAT (53) NOT NULL,
    [StockDate]              DATETIME   NULL,
    [Stock]                  FLOAT (53) NULL,
    [StockAdjustedDelivered] FLOAT (53) NOT NULL,
    [StockAdjustedDispensed] FLOAT (53) NOT NULL,
    [StockAdjustedVariance]  FLOAT (53) NOT NULL,
    [IsAudited]              BIT        DEFAULT ((1)) NOT NULL,
    CONSTRAINT [PK_PeriodCacheVariance_NEW] PRIMARY KEY CLUSTERED ([EDISID] ASC, [WeekCommencing] ASC, [ProductID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_Product]
    ON [dbo].[PeriodCacheVariance]([ProductID] ASC)
    INCLUDE([EDISID], [WeekCommencing], [IsTied], [DeliveredBeforeStock], [DeliveredAfterStock], [Delivered], [Dispensed], [Variance], [StockDate], [Stock], [StockAdjustedDelivered], [StockAdjustedDispensed], [StockAdjustedVariance]);


GO
CREATE NONCLUSTERED INDEX [IX_Variance_Tied_Delivered]
    ON [dbo].[PeriodCacheVariance]([EDISID] ASC, [IsTied] ASC, [WeekCommencing] ASC)
    INCLUDE([Delivered]);


GO
CREATE NONCLUSTERED INDEX [missing_index_10155_10154_PeriodCacheVariance]
    ON [dbo].[PeriodCacheVariance]([IsAudited] ASC, [WeekCommencing] ASC);


GO
CREATE NONCLUSTERED INDEX [missing_index_10159_10158_PeriodCacheVariance]
    ON [dbo].[PeriodCacheVariance]([WeekCommencing] ASC)
    INCLUDE([IsAudited]);


GO
CREATE NONCLUSTERED INDEX [missing_index_16062_16061_PeriodCacheVariance]
    ON [dbo].[PeriodCacheVariance]([IsTied] ASC, [WeekCommencing] ASC)
    INCLUDE([EDISID], [ProductID], [Delivered], [Dispensed], [Variance], [StockAdjustedDelivered], [StockAdjustedDispensed], [IsAudited]);


GO
CREATE NONCLUSTERED INDEX [missing_index_16060_16059_PeriodCacheVariance]
    ON [dbo].[PeriodCacheVariance]([IsTied] ASC, [WeekCommencing] ASC)
    INCLUDE([EDISID], [ProductID], [Dispensed], [StockDate], [StockAdjustedDelivered], [StockAdjustedDispensed], [StockAdjustedVariance], [IsAudited]);


GO
GRANT SELECT
    ON OBJECT::[dbo].[PeriodCacheVariance] TO PUBLIC
    AS [dbo];

