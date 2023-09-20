CREATE TABLE [dbo].[SitePointsCategories] (
    [EDISID]     INT NOT NULL,
    [CategoryID] INT NOT NULL,
    [Points]     INT NOT NULL,
    CONSTRAINT [PK_SitePointsCategories] PRIMARY KEY CLUSTERED ([EDISID] ASC, [CategoryID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_SitePointsCategories_PointsCategories] FOREIGN KEY ([CategoryID]) REFERENCES [dbo].[PointsCategories] ([ID])
);

