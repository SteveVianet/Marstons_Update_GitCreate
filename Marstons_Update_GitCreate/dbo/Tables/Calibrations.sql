CREATE TABLE [dbo].[Calibrations] (
    [EDISID]          INT           NOT NULL,
    [Pump]            INT           NOT NULL,
    [LocationID]      INT           NOT NULL,
    [ProductID]       INT           NOT NULL,
    [FlowMeterTypeID] INT           NOT NULL,
    [ScalarValue1]    INT           NOT NULL,
    [ScalarValue2]    INT           NOT NULL,
    [ScalarValue3]    INT           NOT NULL,
    [ValidFrom]       SMALLDATETIME NOT NULL,
    [ValidTo]         SMALLDATETIME NULL,
    CONSTRAINT [PK_Calibrations] PRIMARY KEY CLUSTERED ([EDISID] ASC, [Pump] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Calibrations_LocationID] FOREIGN KEY ([LocationID]) REFERENCES [dbo].[Locations] ([ID]) ON DELETE CASCADE
);

