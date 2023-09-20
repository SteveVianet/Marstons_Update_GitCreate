CREATE TABLE [dbo].[SiteTradingShifts] (
    [ID]                         INT           IDENTITY (1, 1) NOT NULL,
    [EDISID]                     INT           NOT NULL,
    [ShiftStartTime]             TIME (0)      NOT NULL,
    [ShiftDurationMinutes]       INT           NOT NULL,
    [DayOfWeek]                  INT           NOT NULL,
    [Name]                       VARCHAR (100) NULL,
    [ManuallyAdjustedBySiteUser] BIT           DEFAULT ((0)) NOT NULL,
    [TableColour]                VARCHAR (50)  NULL,
    [TableNumber]                INT           NULL,
    CONSTRAINT [PK_SiteTradingShifts] PRIMARY KEY CLUSTERED ([ID] ASC),
    CONSTRAINT [FK_SiteTradingShifts_Sites] FOREIGN KEY ([EDISID]) REFERENCES [dbo].[Sites] ([EDISID])
);

