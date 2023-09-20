CREATE TABLE [dbo].[WaterStack] (
    [WaterID] INT        NOT NULL,
    [Time]    DATETIME   NOT NULL,
    [Line]    INT        NOT NULL,
    [Volume]  FLOAT (53) NOT NULL,
    CONSTRAINT [PK_WaterStack] PRIMARY KEY CLUSTERED ([WaterID] ASC, [Time] ASC, [Line] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_WaterStack_MasterDates] FOREIGN KEY ([WaterID]) REFERENCES [dbo].[MasterDates] ([ID]) ON DELETE CASCADE
);

