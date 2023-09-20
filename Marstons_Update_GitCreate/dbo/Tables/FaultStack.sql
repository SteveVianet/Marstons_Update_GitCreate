CREATE TABLE [dbo].[FaultStack] (
    [FaultID]     INT           NOT NULL,
    [Description] VARCHAR (255) NULL,
    [Time]        DATETIME      NOT NULL,
    CONSTRAINT [FK_FaultStack_MasterDates] FOREIGN KEY ([FaultID]) REFERENCES [dbo].[MasterDates] ([ID]) ON DELETE CASCADE
);


GO
CREATE CLUSTERED INDEX [IX_FaultStack_FaultID]
    ON [dbo].[FaultStack]([FaultID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [missing_index_1603_1602_FaultStack]
    ON [dbo].[FaultStack]([Description] ASC)
    INCLUDE([FaultID], [Time]);


GO
CREATE NONCLUSTERED INDEX [IX_FaultStack_Description]
    ON [dbo].[FaultStack]([Description] ASC) WITH (FILLFACTOR = 90);

