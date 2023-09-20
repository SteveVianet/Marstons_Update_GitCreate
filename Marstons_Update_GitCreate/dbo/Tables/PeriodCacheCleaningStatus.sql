CREATE TABLE [dbo].[PeriodCacheCleaningStatus] (
    [EDISID]           INT      NOT NULL,
    [Date]             DATETIME NOT NULL,
    [PumpID]           INT      NOT NULL,
    [RealPumpID]       INT      NOT NULL,
    [CleanDays]        INT      NOT NULL,
    [OverdueCleanDays] INT      NOT NULL,
    CONSTRAINT [PK_PeriodCacheCleaningStatus] PRIMARY KEY CLUSTERED ([EDISID] ASC, [Date] ASC, [PumpID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_PeriodCleaning_Date]
    ON [dbo].[PeriodCacheCleaningStatus]([Date] ASC)
    INCLUDE([EDISID], [CleanDays], [OverdueCleanDays]);


GO
CREATE NONCLUSTERED INDEX [IX_Cleaning_Days]
    ON [dbo].[PeriodCacheCleaningStatus]([EDISID] ASC, [Date] ASC)
    INCLUDE([CleanDays], [OverdueCleanDays]);

