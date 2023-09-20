CREATE TABLE [dbo].[ScheduleSites] (
    [ScheduleID] INT NOT NULL,
    [EDISID]     INT NOT NULL,
    CONSTRAINT [PK_ScheduleSites_ScheduleID_EDISID] PRIMARY KEY CLUSTERED ([ScheduleID] ASC, [EDISID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_ScheduleSites_Schedules] FOREIGN KEY ([ScheduleID]) REFERENCES [dbo].[Schedules] ([ID]) ON DELETE CASCADE,
    CONSTRAINT [FK_ScheduleSites_Sites] FOREIGN KEY ([EDISID]) REFERENCES [dbo].[Sites] ([EDISID]) ON DELETE CASCADE
);

