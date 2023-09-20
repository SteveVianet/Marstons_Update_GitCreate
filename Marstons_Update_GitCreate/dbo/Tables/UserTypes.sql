CREATE TABLE [dbo].[UserTypes] (
    [ID]              INT           NOT NULL,
    [Description]     VARCHAR (255) NOT NULL,
    [AllSitesVisible] BIT           CONSTRAINT [DF_UserTypes_AllSitesVisible] DEFAULT (0) NOT NULL,
    CONSTRAINT [PK_UserTypes] PRIMARY KEY CLUSTERED ([ID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [UX_UserTypes] UNIQUE NONCLUSTERED ([Description] ASC) WITH (FILLFACTOR = 90)
);

