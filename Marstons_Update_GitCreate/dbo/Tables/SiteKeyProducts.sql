CREATE TABLE [dbo].[SiteKeyProducts] (
    [EDISID]    INT NOT NULL,
    [ProductID] INT NOT NULL,
    CONSTRAINT [PK_SiteKeyProducts] PRIMARY KEY CLUSTERED ([EDISID] ASC, [ProductID] ASC),
    CONSTRAINT [FK_SiteKeyProducts_Products] FOREIGN KEY ([ProductID]) REFERENCES [dbo].[Products] ([ID]),
    CONSTRAINT [FK_SiteKeyProducts_Sites] FOREIGN KEY ([EDISID]) REFERENCES [dbo].[Sites] ([EDISID])
);


GO
GRANT DELETE
    ON OBJECT::[dbo].[SiteKeyProducts] TO PUBLIC
    AS [dbo];


GO
GRANT SELECT
    ON OBJECT::[dbo].[SiteKeyProducts] TO PUBLIC
    AS [dbo];


GO
GRANT UPDATE
    ON OBJECT::[dbo].[SiteKeyProducts] TO PUBLIC
    AS [dbo];

