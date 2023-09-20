CREATE TABLE [dbo].[SiteRankingTypes] (
    [ID]                 INT           NOT NULL,
    [Priority]           INT           NOT NULL,
    [Colour]             INT           NOT NULL,
    [Name]               VARCHAR (255) NOT NULL,
    [SafeDisplayRanking] INT           NULL,
    [AllowUserSelection] BIT           DEFAULT (0) NOT NULL,
    [ExcelColour]        INT           DEFAULT (0) NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC) WITH (FILLFACTOR = 90)
);

