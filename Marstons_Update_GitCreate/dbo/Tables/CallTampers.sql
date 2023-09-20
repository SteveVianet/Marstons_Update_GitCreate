CREATE TABLE [dbo].[CallTampers] (
    [CallID]   INT           NULL,
    [ReasonID] INT           NULL,
    [Remarks]  VARCHAR (255) NULL,
    FOREIGN KEY ([CallID]) REFERENCES [dbo].[Calls] ([ID])
);

