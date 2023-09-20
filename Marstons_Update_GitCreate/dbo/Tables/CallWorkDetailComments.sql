CREATE TABLE [dbo].[CallWorkDetailComments] (
    [ID]                  INT           IDENTITY (1, 1) NOT NULL,
    [CallID]              INT           NOT NULL,
    [WorkDetailComment]   TEXT          NOT NULL,
    [WorkDetailCommentBy] VARCHAR (255) CONSTRAINT [DF_CallWorkDetailComments_CommentBy] DEFAULT (suser_sname()) NOT NULL,
    [SubmittedOn]         DATETIME      CONSTRAINT [DF_CallWorkDetailComments_SubmittedOn] DEFAULT (getdate()) NOT NULL,
    [EditedOn]            DATETIME      NULL,
    [IsInvoice]           BIT           DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_CallWorkDetailComments] PRIMARY KEY CLUSTERED ([ID] ASC),
    CONSTRAINT [FK_CallWorkDetailComments_ServiceCalls] FOREIGN KEY ([CallID]) REFERENCES [dbo].[Calls] ([ID])
);


GO
CREATE NONCLUSTERED INDEX [missing_index_687_686_CallWorkDetailComments]
    ON [dbo].[CallWorkDetailComments]([CallID] ASC)
    INCLUDE([ID]);


GO
CREATE NONCLUSTERED INDEX [missing_index_7665_7664_CallWorkDetailComments]
    ON [dbo].[CallWorkDetailComments]([CallID] ASC);

