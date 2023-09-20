CREATE TABLE [dbo].[PeriodCacheYield] (
    [EDISID]           INT        NOT NULL,
    [DispenseDay]      DATETIME   NOT NULL,
    [CategoryID]       INT        NOT NULL,
    [Quantity]         FLOAT (53) NOT NULL,
    [Drinks]           FLOAT (53) NOT NULL,
    [OutsideThreshold] BIT        DEFAULT ((0)) NOT NULL,
    [CleaningWaste]    FLOAT (53) NULL,
    CONSTRAINT [PK_PeriodCacheYield] PRIMARY KEY CLUSTERED ([EDISID] ASC, [DispenseDay] ASC, [CategoryID] ASC, [OutsideThreshold] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_PeriodCacheYield_EDISID_Date]
    ON [dbo].[PeriodCacheYield]([EDISID] ASC, [DispenseDay] ASC);

