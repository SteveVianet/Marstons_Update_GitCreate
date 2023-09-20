CREATE TABLE [dbo].[Issues] (
    [ID]          INT           IDENTITY (1, 1) NOT NULL,
    [EDISID]      INT           NOT NULL,
    [IssueText]   VARCHAR (255) NOT NULL,
    [SubmittedOn] SMALLDATETIME CONSTRAINT [DF_Issues_SubmittedOn] DEFAULT (getdate()) NOT NULL,
    [SubmittedBy] VARCHAR (255) CONSTRAINT [DF_Issues_SubmittedBy] DEFAULT (suser_sname()) NOT NULL,
    [Viewed]      BIT           CONSTRAINT [DF_Issues_Viewed] DEFAULT (0) NOT NULL,
    [ViewedOn]    SMALLDATETIME NULL,
    [ViewedBy]    VARCHAR (255) NULL,
    [Deleted]     BIT           CONSTRAINT [DF_Issues_Deleted] DEFAULT (0) NOT NULL,
    [DeletedOn]   SMALLDATETIME NULL,
    [DeletedBy]   VARCHAR (255) NULL,
    [CategoryID]  INT           CONSTRAINT [DF_Issues_CategoryID] DEFAULT (1) NOT NULL,
    CONSTRAINT [PK_Issues] PRIMARY KEY CLUSTERED ([ID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Issues_IssueCategories] FOREIGN KEY ([CategoryID]) REFERENCES [dbo].[IssueCategories] ([ID]) ON DELETE CASCADE,
    CONSTRAINT [FK_Issues_Sites] FOREIGN KEY ([EDISID]) REFERENCES [dbo].[Sites] ([EDISID]) ON DELETE CASCADE
);


GO
CREATE NONCLUSTERED INDEX [IX_Issues]
    ON [dbo].[Issues]([EDISID] ASC) WITH (FILLFACTOR = 90);

