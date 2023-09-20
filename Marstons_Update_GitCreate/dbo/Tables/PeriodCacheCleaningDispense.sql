CREATE TABLE [dbo].[PeriodCacheCleaningDispense] (
    [EDISID]               INT        NOT NULL,
    [Date]                 DATETIME   NOT NULL,
    [CategoryID]           INT        NOT NULL,
    [TotalDispense]        FLOAT (53) NOT NULL,
    [CleanDispense]        FLOAT (53) NOT NULL,
    [DueCleanDispense]     FLOAT (53) NOT NULL,
    [OverdueCleanDispense] FLOAT (53) NOT NULL,
    CONSTRAINT [PK_PeriodCacheCleaningDispense] PRIMARY KEY CLUSTERED ([EDISID] ASC, [Date] ASC, [CategoryID] ASC),
    CONSTRAINT [FK_PeriodCacheCleaningDispense_ProductCategories] FOREIGN KEY ([CategoryID]) REFERENCES [dbo].[ProductCategories] ([ID]),
    CONSTRAINT [FK_PeriodCacheCleaningDispense_Sites] FOREIGN KEY ([EDISID]) REFERENCES [dbo].[Sites] ([EDISID])
);

