CREATE TABLE [dbo].[SiteLocations] (
    [EDISID]    INT        NOT NULL,
    [LocationX] FLOAT (53) NOT NULL,
    [LocationY] FLOAT (53) NOT NULL,
    CONSTRAINT [PK_SiteLocations] PRIMARY KEY CLUSTERED ([EDISID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_SiteLocations_Sites] FOREIGN KEY ([EDISID]) REFERENCES [dbo].[Sites] ([EDISID])
);

