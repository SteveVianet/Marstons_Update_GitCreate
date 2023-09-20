CREATE TABLE [dbo].[SiteRankings_Backup] (
    [EDISID]            INT            NOT NULL,
    [ValidFrom]         SMALLDATETIME  NOT NULL,
    [ValidTo]           SMALLDATETIME  NULL,
    [RankingTypeID]     INT            NOT NULL,
    [ManualText]        VARCHAR (1024) NOT NULL,
    [AssignedBy]        VARCHAR (255)  NOT NULL,
    [RankingCategoryID] INT            NOT NULL
);

