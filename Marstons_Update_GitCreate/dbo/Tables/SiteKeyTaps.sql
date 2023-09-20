CREATE TABLE [dbo].[SiteKeyTaps] (
    [EDISID] INT NOT NULL,
    [Pump]   INT NOT NULL,
    [Type]   INT NOT NULL,
    CONSTRAINT [PK_SiteKeyTaps] PRIMARY KEY CLUSTERED ([EDISID] ASC, [Pump] ASC),
    CONSTRAINT [FK_SiteKeyTaps_Sites] FOREIGN KEY ([EDISID]) REFERENCES [dbo].[Sites] ([EDISID])
);

