CREATE TABLE [dbo].[PeriodCacheTemperature] (
    [EDISID]        INT        NOT NULL,
    [Date]          DATETIME   NOT NULL,
    [CategoryID]    INT        NOT NULL,
    [TotalDispense] FLOAT (53) NOT NULL,
    [InSpec]        FLOAT (53) NOT NULL,
    [InTolerance]   FLOAT (53) NOT NULL,
    [OutSpec]       FLOAT (53) NOT NULL,
    CONSTRAINT [PK_PeriodCacheTemperature] PRIMARY KEY CLUSTERED ([EDISID] ASC, [Date] ASC, [CategoryID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_PeriodCacheTemperature_EDISID_Date]
    ON [dbo].[PeriodCacheTemperature]([EDISID] ASC, [Date] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_PeriodCacheTemperature_Date_EDISID_CategoryID]
    ON [dbo].[PeriodCacheTemperature]([Date] ASC)
    INCLUDE([EDISID], [CategoryID]);

