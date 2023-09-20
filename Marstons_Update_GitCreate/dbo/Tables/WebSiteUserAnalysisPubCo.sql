CREATE TABLE [dbo].[WebSiteUserAnalysisPubCo] (
    [WeekCommencing]       DATE NOT NULL,
    [RMID]                 INT  NOT NULL,
    [BDMID]                INT  NOT NULL,
    [BDMLoginCount]        INT  CONSTRAINT [DF_WebSiteUserAnalysisPubCo_BDMLoginCount] DEFAULT ((0)) NOT NULL,
    [BDMSessionAverage]    INT  CONSTRAINT [DF_WebSiteUserAnalysisPubCo_BDMSessionAverage] DEFAULT ((0)) NOT NULL,
    [BDMLiveIDraughtSites] INT  CONSTRAINT [DF_WebSiteUserAnalysisPubCo_BDMLiveIDraughtSites] DEFAULT ((0)) NOT NULL,
    [BDMLiveDMSSites]      INT  CONSTRAINT [DF_WebSiteUserAnalysisPubCo_BDMLiveDMSSites] DEFAULT ((0)) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [IX_PubCoUsers_WeekCommencing_RMID_BDMID]
    ON [dbo].[WebSiteUserAnalysisPubCo]([WeekCommencing] ASC, [RMID] ASC, [BDMID] ASC);

