CREATE TABLE [dbo].[SiteQualityHistory] (
    [EDISID]       INT  NOT NULL,
    [QualityStart] DATE NOT NULL,
    [QualityEnd]   DATE NULL,
    CONSTRAINT [PK_SiteQualityHistory] PRIMARY KEY CLUSTERED ([EDISID] ASC, [QualityStart] ASC),
    CONSTRAINT [FK_SiteQualityHistory_Sites] FOREIGN KEY ([EDISID]) REFERENCES [dbo].[Sites] ([EDISID])
);

