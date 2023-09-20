CREATE TABLE [dbo].[SiteClosingHours] (
    [EDISID]    INT     NOT NULL,
    [WeekDay]   TINYINT NOT NULL,
    [HourOfDay] TINYINT NOT NULL,
    PRIMARY KEY CLUSTERED ([EDISID] ASC, [WeekDay] ASC, [HourOfDay] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [CK_SiteClosingHours_HourOfDay] CHECK ([HourOfDay] >= 0 and [HourOfDay] <= 23),
    CONSTRAINT [CK_SiteClosingHours_WeekDay] CHECK ([WeekDay] >= 1 and [WeekDay] <= 7),
    FOREIGN KEY ([EDISID]) REFERENCES [dbo].[Sites] ([EDISID])
);


GO
CREATE NONCLUSTERED INDEX [IX_SiteClosingHours_EDISID]
    ON [dbo].[SiteClosingHours]([EDISID] ASC) WITH (FILLFACTOR = 90);

