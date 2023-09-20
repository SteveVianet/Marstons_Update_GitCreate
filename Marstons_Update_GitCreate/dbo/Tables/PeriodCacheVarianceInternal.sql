CREATE TABLE [dbo].[PeriodCacheVarianceInternal] (
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
    CONSTRAINT [PK_PeriodCacheVarianceInternal_NEW] PRIMARY KEY CLUSTERED ([EDISID] ASC, [WeekCommencing] ASC, [ProductID] ASC)
);

