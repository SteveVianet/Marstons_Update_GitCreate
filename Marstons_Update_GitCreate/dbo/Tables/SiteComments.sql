CREATE TABLE [dbo].[SiteComments] (
    [ID]          INT            IDENTITY (1, 1) NOT NULL,
    [EDISID]      INT            NOT NULL,
    [Type]        INT            NOT NULL,
    [Date]        DATETIME       NOT NULL,
    [HeadingType] INT            NOT NULL,
    [Text]        VARCHAR (1024) NOT NULL,
    [AddedOn]     DATETIME       CONSTRAINT [DF_SiteComments_AddedOn] DEFAULT (getdate()) NOT NULL,
    [AddedBy]     VARCHAR (255)  CONSTRAINT [DF_SiteComments_AddedBy] DEFAULT (suser_sname()) NOT NULL,
    [EditedOn]    DATETIME       CONSTRAINT [DF_SiteComments_EditedOn] DEFAULT (getdate()) NOT NULL,
    [EditedBy]    VARCHAR (255)  CONSTRAINT [DF_SiteComments_EditedBy] DEFAULT (suser_sname()) NOT NULL,
    [Deleted]     BIT            DEFAULT (0) NOT NULL,
    [RAGStatus]   VARCHAR (50)   NULL,
    CONSTRAINT [PK_SiteComments] PRIMARY KEY CLUSTERED ([ID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_SiteComments_Sites] FOREIGN KEY ([EDISID]) REFERENCES [dbo].[Sites] ([EDISID])
);


GO
CREATE NONCLUSTERED INDEX [IX_SiteComments_Date]
    ON [dbo].[SiteComments]([Date] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_SiteComments_Type]
    ON [dbo].[SiteComments]([Type] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_SiteComments_HeadingType]
    ON [dbo].[SiteComments]([HeadingType] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_SiteComments_EDISID]
    ON [dbo].[SiteComments]([EDISID] ASC);


GO
CREATE NONCLUSTERED INDEX [missing_index_230_229_SiteComments]
    ON [dbo].[SiteComments]([Type] ASC)
    INCLUDE([ID], [EDISID], [Date]);

