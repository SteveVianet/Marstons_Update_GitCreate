CREATE TABLE [dbo].[SiteRankings] (
    [EDISID]            INT            NOT NULL,
    [ValidFrom]         SMALLDATETIME  NOT NULL,
    [ValidTo]           SMALLDATETIME  NULL,
    [RankingTypeID]     INT            NOT NULL,
    [ManualText]        VARCHAR (1024) NOT NULL,
    [AssignedBy]        VARCHAR (255)  CONSTRAINT [DF_SiteRankings_AssignedBy] DEFAULT (suser_sname()) NOT NULL,
    [RankingCategoryID] INT            DEFAULT (1) NOT NULL,
    CONSTRAINT [PK_SiteRankings] PRIMARY KEY CLUSTERED ([EDISID] ASC, [ValidFrom] ASC, [RankingCategoryID] ASC),
    CONSTRAINT [FK_SiteRankings_EDISID] FOREIGN KEY ([EDISID]) REFERENCES [dbo].[Sites] ([EDISID]),
    CONSTRAINT [FK_SiteRankings_SiteRankingTypes] FOREIGN KEY ([RankingTypeID]) REFERENCES [dbo].[SiteRankingTypes] ([ID])
);

