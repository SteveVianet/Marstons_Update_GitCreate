CREATE TABLE [dbo].[CleaningStack] (
    [CleaningID] INT        NOT NULL,
    [Time]       DATETIME   NOT NULL,
    [Line]       INT        NOT NULL,
    [Volume]     FLOAT (53) NOT NULL,
    CONSTRAINT [PK_CleaningStack] PRIMARY KEY CLUSTERED ([CleaningID] ASC, [Time] ASC, [Line] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_CleaningStack_MasterDates] FOREIGN KEY ([CleaningID]) REFERENCES [dbo].[MasterDates] ([ID]) ON DELETE CASCADE
);

