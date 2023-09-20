CREATE TABLE [dbo].[CallComments] (
    [ID]          INT           IDENTITY (1, 1) NOT NULL,
    [CallID]      INT           NOT NULL,
    [Comment]     TEXT          NOT NULL,
    [CommentBy]   VARCHAR (255) CONSTRAINT [DF_CallComments_CommentBy] DEFAULT (suser_sname()) NOT NULL,
    [SubmittedOn] DATETIME      CONSTRAINT [DF_CallComments_SubmittedOn] DEFAULT (getdate()) NOT NULL,
    [EditedOn]    DATETIME      NULL,
    CONSTRAINT [PK_CallComments] PRIMARY KEY CLUSTERED ([ID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_CallComments_Calls] FOREIGN KEY ([CallID]) REFERENCES [dbo].[Calls] ([ID])
);

