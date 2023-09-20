CREATE TABLE [dbo].[Reds] (
    [DatabaseID]                   INT          NOT NULL,
    [Period]                       VARCHAR (10) NOT NULL,
    [EDISID]                       INT          NOT NULL,
    [CategoryID]                   INT          NULL,
    [ProductID]                    INT          NULL,
    [AreValuesStockAdjusted]       INT          NULL,
    [FromWeek]                     DATETIME     NULL,
    [AdjustedFromWeek]             DATETIME     NULL,
    [ToWeek]                       DATETIME     NULL,
    [ReportWeeks]                  INT          NULL,
    [AdjustedReportWeeks]          INT          NULL,
    [PeriodWeeks]                  INT          NULL,
    [PeriodDelivered]              FLOAT (53)   NULL,
    [PeriodDispensed]              FLOAT (53)   NULL,
    [PeriodVariance]               FLOAT (53)   NULL,
    [LowDispensedThreshold]        FLOAT (53)   NULL,
    [InsufficientData]             INT          NULL,
    [MinimumCumulative]            FLOAT (53)   NULL,
    [MinimumCumulativePre]         FLOAT (53)   NULL,
    [CD]                           FLOAT (53)   NULL,
    [RunCode]                      INT          NULL,
    [CDLowVol]                     INT          CONSTRAINT [DF_Reds_CDLowVol] DEFAULT ((0)) NULL,
    [CDLowPctOfRange]              INT          CONSTRAINT [DF_Reds_CDLowPctOfRange] DEFAULT ((0)) NULL,
    [SiteLowCategoryDispRemaining] INT          CONSTRAINT [DF_Reds_SiteLowProductDispRemaining] DEFAULT ((0)) NULL,
    [SiteLowProductDispRemaining]  INT          CONSTRAINT [DF_Reds_SiteLowProductDispRemaining1] DEFAULT ((0)) NULL,
    [ReportThis]                   INT          CONSTRAINT [DF_Reds_SiteLowCategoryDispRemaining1] DEFAULT ((0)) NULL,
    [DeleteThis]                   INT          NULL,
    [Corrected]                    VARCHAR (10) NULL
);


GO
CREATE NONCLUSTERED INDEX [INX_RunCode]
    ON [dbo].[Reds]([RunCode] ASC)
    INCLUDE([DatabaseID], [Period], [EDISID], [PeriodDispensed], [CD]);

