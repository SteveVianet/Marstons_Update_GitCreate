CREATE TABLE [dbo].[SiteExceptionConfiguration] (
    [EDISID]                          INT        NOT NULL,
    [ProductTempAlarmsEnabled]        BIT        NULL,
    [ProductTempHighPercentThreshold] INT        NULL,
    [CleaningAlarmsEnabled]           BIT        NULL,
    [OverallYieldAlarmsEnabled]       BIT        NULL,
    [OverallYieldLowPercentThreshold] INT        NULL,
    [PouringYieldAlarmsEnabled]       BIT        NULL,
    [PouringYieldLowPercentThreshold] INT        NULL,
    [RetailYieldAlarmsEnabled]        BIT        NULL,
    [RetailYieldLowPercentThreshold]  INT        NULL,
    [ThroughputAlarmsEnabled]         BIT        NULL,
    [ThroughputMinThreshold]          INT        NULL,
    [OutOfHoursDispenseAlarmsEnabled] BIT        NULL,
    [OutOfHoursDispenseMinThreshold]  FLOAT (53) NULL,
    [NoDataAlarmsEnabled]             BIT        NULL,
    [CleaningLowVolumeThreshold]      FLOAT (53) DEFAULT ((1)) NOT NULL,
    [OverallYieldHighVolumeThreshold] FLOAT (53) DEFAULT ((0)) NOT NULL,
    [RetailYieldHighVolumeThreshold]  FLOAT (53) DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_SiteExceptionConfiguration] PRIMARY KEY CLUSTERED ([EDISID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_SiteExceptionConfiguration_Sites] FOREIGN KEY ([EDISID]) REFERENCES [dbo].[Sites] ([EDISID])
);

