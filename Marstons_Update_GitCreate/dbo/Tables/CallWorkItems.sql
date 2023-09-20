CREATE TABLE [dbo].[CallWorkItems] (
    [CallID]     INT NOT NULL,
    [WorkItemID] INT NOT NULL,
    CONSTRAINT [PK_CallWorkItems] PRIMARY KEY CLUSTERED ([CallID] ASC, [WorkItemID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_CallWorkItems_Calls] FOREIGN KEY ([CallID]) REFERENCES [dbo].[Calls] ([ID])
);

