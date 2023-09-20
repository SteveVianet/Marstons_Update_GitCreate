CREATE TABLE [dbo].[PeriodCacheYieldDaily] (
    [EDISID]           INT        NOT NULL,
    [DispenseDay]      DATETIME   NOT NULL,
    [CategoryID]       INT        NOT NULL,
    [Quantity]         FLOAT (53) NOT NULL,
    [Drinks]           FLOAT (53) NOT NULL,
    [OutsideThreshold] BIT        DEFAULT ((0)) NOT NULL,
    [CleaningWaste]    FLOAT (53) NULL,
    CONSTRAINT [PK_PeriodCacheYieldDaily] PRIMARY KEY CLUSTERED ([EDISID] ASC, [DispenseDay] ASC, [CategoryID] ASC, [OutsideThreshold] ASC)
);

