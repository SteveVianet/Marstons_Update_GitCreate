CREATE TABLE [dbo].[PATTracking] (
    [ApplianceID]        NVARCHAR (10) NOT NULL,
    [CallID]             INT           NOT NULL,
    [PanelInstalled]     SMALLDATETIME NULL,
    [TestDate]           SMALLDATETIME NOT NULL,
    [ReTestDue]          SMALLDATETIME NOT NULL,
    [Visual]             TINYINT       NOT NULL,
    [Polarity]           TINYINT       NOT NULL,
    [EarthCont]          TINYINT       NOT NULL,
    [EarthContOperator]  TINYINT       NOT NULL,
    [EarthContReading]   FLOAT (53)    NULL,
    [Insulation]         TINYINT       NOT NULL,
    [InsulationOperator] TINYINT       NOT NULL,
    [InsulationReading]  FLOAT (53)    NULL,
    [Load]               TINYINT       NOT NULL,
    [LoadOperator]       TINYINT       NOT NULL,
    [LoadReading]        FLOAT (53)    NULL,
    [Leakage]            TINYINT       NOT NULL,
    [LeakageOperator]    TINYINT       NOT NULL,
    [LeakageReading]     FLOAT (53)    NULL,
    [TouchLeak]          TINYINT       NOT NULL,
    [SubLeak]            TINYINT       NOT NULL,
    [Flash]              TINYINT       NOT NULL,
    [TouchLeakReading]   FLOAT (53)    NULL,
    [TouchLeakOperator]  TINYINT       NULL,
    CONSTRAINT [PK_PATTracking] PRIMARY KEY CLUSTERED ([CallID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_PATTracking_TestDate]
    ON [dbo].[PATTracking]([TestDate] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_PATTracking_ReTest]
    ON [dbo].[PATTracking]([ReTestDue] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_PATTracking_ApplienceID]
    ON [dbo].[PATTracking]([ApplianceID] ASC);

