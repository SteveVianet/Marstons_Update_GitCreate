CREATE TABLE [dbo].[IssueCategories] (
    [ID]          INT           IDENTITY (1, 1) NOT NULL,
    [Description] VARCHAR (255) NOT NULL,
    [Urgent]      BIT           CONSTRAINT [DF_IssueCategories_Urgent] DEFAULT (0) NOT NULL,
    CONSTRAINT [PK_IssueCategories] PRIMARY KEY CLUSTERED ([ID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [UX_IssueCategories] UNIQUE NONCLUSTERED ([Description] ASC) WITH (FILLFACTOR = 90)
);

