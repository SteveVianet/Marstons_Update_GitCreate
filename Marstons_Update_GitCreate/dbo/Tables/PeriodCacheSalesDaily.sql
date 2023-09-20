CREATE TABLE [dbo].[PeriodCacheSalesDaily] (
    [EDISID]     INT        NOT NULL,
    [SaleDay]    DATETIME   NOT NULL,
    [CategoryID] INT        NOT NULL,
    [Sold]       FLOAT (53) NOT NULL
);

