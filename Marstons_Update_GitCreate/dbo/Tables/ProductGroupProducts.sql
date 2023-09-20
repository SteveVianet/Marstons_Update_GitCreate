CREATE TABLE [dbo].[ProductGroupProducts] (
    [ProductGroupID] INT NOT NULL,
    [ProductID]      INT NOT NULL,
    [IsPrimary]      BIT DEFAULT (0) NOT NULL,
    CONSTRAINT [ProductGroupProducts_pk] PRIMARY KEY CLUSTERED ([ProductGroupID] ASC, [ProductID] ASC),
    CONSTRAINT [FK_ProductGroupProducts_ProductGroups] FOREIGN KEY ([ProductGroupID]) REFERENCES [dbo].[ProductGroups] ([ID]),
    CONSTRAINT [FK_ProductGroupProducts_Products] FOREIGN KEY ([ProductID]) REFERENCES [dbo].[Products] ([ID])
);

