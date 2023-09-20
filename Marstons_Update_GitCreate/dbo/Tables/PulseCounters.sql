CREATE TABLE [dbo].[PulseCounters] (
    [MeterID]         INT        NOT NULL,
    [DigitID]         INT        NOT NULL,
    [Date]            DATETIME   NOT NULL,
    [Time]            DATETIME   NOT NULL,
    [CounterPosition] TINYINT    NOT NULL,
    [CounterValue]    FLOAT (53) NOT NULL,
    CONSTRAINT [PK_PulseCounters] PRIMARY KEY CLUSTERED ([MeterID] ASC, [Date] ASC, [Time] ASC, [CounterPosition] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_PulseCounters_Meters] FOREIGN KEY ([MeterID]) REFERENCES [dbo].[Meters] ([ID]) ON DELETE CASCADE
);

