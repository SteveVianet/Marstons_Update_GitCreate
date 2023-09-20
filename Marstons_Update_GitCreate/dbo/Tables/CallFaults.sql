CREATE TABLE [dbo].[CallFaults] (
    [ID]             INT           IDENTITY (1, 1) NOT NULL,
    [CallID]         INT           NOT NULL,
    [FaultTypeID]    INT           NOT NULL,
    [AdditionalInfo] VARCHAR (255) NULL,
    [SLA]            INT           NULL,
    CONSTRAINT [PK_CallFaults] PRIMARY KEY CLUSTERED ([ID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_CallFaults_Calls] FOREIGN KEY ([CallID]) REFERENCES [dbo].[Calls] ([ID])
);


GO
CREATE NONCLUSTERED INDEX [missing_index_623_622_CallFaults]
    ON [dbo].[CallFaults]([CallID] ASC);

