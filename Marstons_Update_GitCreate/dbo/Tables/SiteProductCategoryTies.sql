CREATE TABLE [dbo].[SiteProductCategoryTies] (
    [EDISID]            INT NOT NULL,
    [ProductCategoryID] INT NOT NULL,
    [Tied]              BIT NOT NULL,
    CONSTRAINT [PK_SiteProductCategoryTies] PRIMARY KEY CLUSTERED ([EDISID] ASC, [ProductCategoryID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_SiteProductCategoryTies_ProductCategories] FOREIGN KEY ([ProductCategoryID]) REFERENCES [dbo].[ProductCategories] ([ID]),
    CONSTRAINT [FK_SiteProductCategoryTies_Sites] FOREIGN KEY ([EDISID]) REFERENCES [dbo].[Sites] ([EDISID])
);

