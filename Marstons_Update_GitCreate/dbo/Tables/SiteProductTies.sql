CREATE TABLE [dbo].[SiteProductTies] (
    [EDISID]    INT NOT NULL,
    [ProductID] INT NOT NULL,
    [Tied]      BIT NOT NULL,
    CONSTRAINT [PK_SiteProductTies] PRIMARY KEY CLUSTERED ([EDISID] ASC, [ProductID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_SiteProductTies_Products] FOREIGN KEY ([ProductID]) REFERENCES [dbo].[Products] ([ID]),
    CONSTRAINT [FK_SiteProductTies_Sites] FOREIGN KEY ([EDISID]) REFERENCES [dbo].[Sites] ([EDISID])
);

