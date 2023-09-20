CREATE TABLE [dbo].[Calendar] (
    [CalendarDate]     DATE         NOT NULL,
    [CalendarYear]     INT          NOT NULL,
    [CalendarMonth]    INT          NOT NULL,
    [CalendarWeek]     INT          NOT NULL,
    [CalendarDay]      INT          NOT NULL,
    [DayOfWeek]        INT          NOT NULL,
    [DayOfWeekName]    VARCHAR (10) NOT NULL,
    [FirstDateOfWeek]  DATE         NOT NULL,
    [LastDateOfWeek]   DATE         NOT NULL,
    [FridayOfWeek]     DATE         NOT NULL,
    [FirstDateOfMonth] DATE         NOT NULL,
    [LastDateOfMonth]  DATE         NOT NULL,
    [FirstDateOfYear]  DATE         NOT NULL,
    [LastDateOfYear]   DATE         NOT NULL,
    [Weekday]          BIT          NOT NULL
);


GO
CREATE NONCLUSTERED INDEX [IDX_Calendar_CalendarDate_FirstDateOfWeek]
    ON [dbo].[Calendar]([CalendarDate] ASC)
    INCLUDE([FirstDateOfWeek]);


GO
CREATE NONCLUSTERED INDEX [IDX_Calendar_FirstDateOfWeek]
    ON [dbo].[Calendar]([FirstDateOfWeek] ASC);

