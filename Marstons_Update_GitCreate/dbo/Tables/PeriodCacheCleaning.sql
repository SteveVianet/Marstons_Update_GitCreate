CREATE TABLE [dbo].[PeriodCacheCleaning] (
    [EDISID]             INT      NOT NULL,
    [DispenseWeek]       DATETIME NOT NULL,
    [CategoryID]         INT      NOT NULL,
    [ActiveLines]        INT      NOT NULL,
    [ActiveLinesCleaned] INT      NOT NULL,
    CONSTRAINT [PK_PeriodCacheCleaning] PRIMARY KEY CLUSTERED ([EDISID] ASC, [DispenseWeek] ASC, [CategoryID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_EDISID_Date]
    ON [dbo].[PeriodCacheCleaning]([EDISID] ASC, [DispenseWeek] ASC);

