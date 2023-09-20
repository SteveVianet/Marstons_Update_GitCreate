CREATE TABLE [dbo].[PeriodCacheSales] (
    [EDISID]     INT        NOT NULL,
    [SaleDay]    DATETIME   NOT NULL,
    [CategoryID] INT        NOT NULL,
    [Sold]       FLOAT (53) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [PK_PeriodCacheSales]
    ON [dbo].[PeriodCacheSales]([EDISID] ASC, [SaleDay] ASC, [CategoryID] ASC);

