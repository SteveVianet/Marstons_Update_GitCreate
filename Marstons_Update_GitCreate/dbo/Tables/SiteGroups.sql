CREATE TABLE [dbo].[SiteGroups] (
    [ID]          INT           IDENTITY (1, 1) NOT NULL,
    [Description] VARCHAR (255) NOT NULL,
    [TypeID]      INT           DEFAULT (1) NOT NULL,
    CONSTRAINT [PK_SiteGroups] PRIMARY KEY CLUSTERED ([ID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_SiteGroups_SiteGroupTypes] FOREIGN KEY ([TypeID]) REFERENCES [dbo].[SiteGroupTypes] ([ID]),
    CONSTRAINT [UX_SiteGroups_Description] UNIQUE NONCLUSTERED ([Description] ASC) WITH (FILLFACTOR = 90)
);

