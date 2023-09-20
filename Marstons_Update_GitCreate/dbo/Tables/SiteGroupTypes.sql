CREATE TABLE [dbo].[SiteGroupTypes] (
    [ID]          INT           NOT NULL,
    [Description] VARCHAR (255) NOT NULL,
    [HasPrimary]  BIT           NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

