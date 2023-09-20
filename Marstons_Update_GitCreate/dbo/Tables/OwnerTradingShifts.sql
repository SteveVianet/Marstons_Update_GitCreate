CREATE TABLE [dbo].[OwnerTradingShifts] (
    [ID]                   INT           IDENTITY (1, 1) NOT NULL,
    [OwnerID]              INT           NOT NULL,
    [ShiftStartTime]       TIME (0)      NOT NULL,
    [ShiftDurationMinutes] INT           NOT NULL,
    [DayOfWeek]            INT           NOT NULL,
    [Name]                 VARCHAR (100) NULL,
    [TableColour]          VARCHAR (50)  NULL,
    [TableNumber]          INT           NULL,
    CONSTRAINT [PK_OwnerTradingShifts] PRIMARY KEY CLUSTERED ([ID] ASC),
    CONSTRAINT [FK_OwnerTradingShifts_Sites] FOREIGN KEY ([OwnerID]) REFERENCES [dbo].[Owners] ([ID])
);

