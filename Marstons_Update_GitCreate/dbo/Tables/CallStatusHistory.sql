CREATE TABLE [dbo].[CallStatusHistory] (
    [ID]          INT           IDENTITY (1, 1) NOT NULL,
    [CallID]      INT           NOT NULL,
    [StatusID]    INT           NOT NULL,
    [SubStatusID] INT           CONSTRAINT [DF_CallStatusHistory_SubStatusID] DEFAULT ((-1)) NOT NULL,
    [ChangedOn]   DATETIME      CONSTRAINT [DF_CallStatusHistory_ChangedOn] DEFAULT (getdate()) NOT NULL,
    [ChangedBy]   VARCHAR (255) CONSTRAINT [DF_CallStatusHistory_ChangedBy] DEFAULT (suser_sname()) NOT NULL,
    CONSTRAINT [PK_CallStatusHistory] PRIMARY KEY CLUSTERED ([CallID] ASC, [StatusID] ASC, [SubStatusID] ASC, [ChangedOn] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_CallStatusHistory_Calls] FOREIGN KEY ([CallID]) REFERENCES [dbo].[Calls] ([ID])
);


GO
CREATE NONCLUSTERED INDEX [IX_CallStatusHistory_CallID_ID]
    ON [dbo].[CallStatusHistory]([CallID] ASC, [ID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_CallStatusHistory_ID]
    ON [dbo].[CallStatusHistory]([ID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [missing_index_635_634_CallStatusHistory]
    ON [dbo].[CallStatusHistory]([StatusID] ASC)
    INCLUDE([ID], [CallID]);

