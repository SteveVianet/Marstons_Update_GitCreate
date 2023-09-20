CREATE TABLE [dbo].[SiteGroupSites] (
    [SiteGroupID] INT NOT NULL,
    [EDISID]      INT NOT NULL,
    [IsPrimary]   BIT DEFAULT (0) NOT NULL,
    CONSTRAINT [PK_SiteGroupSites] PRIMARY KEY CLUSTERED ([SiteGroupID] ASC, [EDISID] ASC),
    CONSTRAINT [FK_SiteGroupSites_SiteGroups] FOREIGN KEY ([SiteGroupID]) REFERENCES [dbo].[SiteGroups] ([ID]),
    CONSTRAINT [FK_SiteGroupSites_Sites] FOREIGN KEY ([EDISID]) REFERENCES [dbo].[Sites] ([EDISID])
);

