CREATE TABLE [dbo].[SiteKeyTaps] (
    [EDISID] INT NOT NULL,
    [Pump]   INT NOT NULL,
    [Type]   INT NOT NULL,
    CONSTRAINT [PK_SiteKeyTaps] PRIMARY KEY CLUSTERED ([EDISID] ASC, [Pump] ASC),
    CONSTRAINT [FK_SiteKeyTaps_Sites] FOREIGN KEY ([EDISID]) REFERENCES [dbo].[Sites] ([EDISID])
);


GO
GRANT DELETE
    ON OBJECT::[dbo].[SiteKeyTaps] TO PUBLIC
    AS [dbo];


GO
GRANT SELECT
    ON OBJECT::[dbo].[SiteKeyTaps] TO PUBLIC
    AS [dbo];


GO
GRANT UPDATE
    ON OBJECT::[dbo].[SiteKeyTaps] TO PUBLIC
    AS [dbo];

