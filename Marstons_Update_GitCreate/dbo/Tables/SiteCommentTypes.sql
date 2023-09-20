CREATE TABLE [dbo].[SiteCommentTypes] (
    [ID]          INT           NOT NULL,
    [Description] VARCHAR (100) NOT NULL,
    CONSTRAINT [PK_SiteCommentTypes] PRIMARY KEY CLUSTERED ([ID] ASC),
    UNIQUE NONCLUSTERED ([ID] ASC)
);

