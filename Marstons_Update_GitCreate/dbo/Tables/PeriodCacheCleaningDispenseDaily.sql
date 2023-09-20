CREATE TABLE [dbo].[PeriodCacheCleaningDispenseDaily] (
    [EDISID]               INT        NOT NULL,
    [Date]                 DATETIME   NOT NULL,
    [CategoryID]           INT        NOT NULL,
    [TotalDispense]        FLOAT (53) NOT NULL,
    [CleanDispense]        FLOAT (53) NOT NULL,
    [DueCleanDispense]     FLOAT (53) NOT NULL,
    [OverdueCleanDispense] FLOAT (53) NOT NULL,
    CONSTRAINT [PK_PeriodCacheCleaningDispenseDaily] PRIMARY KEY CLUSTERED ([EDISID] ASC, [Date] ASC, [CategoryID] ASC),
    CONSTRAINT [FK_PeriodCacheCleaningDispenseDaily_ProductCategories] FOREIGN KEY ([CategoryID]) REFERENCES [dbo].[ProductCategories] ([ID]),
    CONSTRAINT [FK_PeriodCacheCleaningDispenseDaily_Sites] FOREIGN KEY ([EDISID]) REFERENCES [dbo].[Sites] ([EDISID])
);

