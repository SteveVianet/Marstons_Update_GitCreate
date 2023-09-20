CREATE TABLE [dbo].[SiteProperties] (
    [EDISID]     INT           NOT NULL,
    [PropertyID] INT           NOT NULL,
    [Value]      VARCHAR (255) NOT NULL,
    CONSTRAINT [FK_SiteProperties_Properties] FOREIGN KEY ([PropertyID]) REFERENCES [dbo].[Properties] ([ID]) ON DELETE CASCADE,
    CONSTRAINT [FK_SiteProperties_Sites] FOREIGN KEY ([EDISID]) REFERENCES [dbo].[Sites] ([EDISID]) ON DELETE CASCADE,
    CONSTRAINT [UX_SiteProperties_EDISID_PropertyID] UNIQUE NONCLUSTERED ([EDISID] ASC, [PropertyID] ASC) WITH (FILLFACTOR = 90)
);


GO
CREATE CLUSTERED INDEX [IX_SiteProperties_EDISID_Property]
    ON [dbo].[SiteProperties]([EDISID] ASC, [PropertyID] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_SiteProperty_Property]
    ON [dbo].[SiteProperties]([PropertyID] ASC)
    INCLUDE([EDISID], [Value]);

