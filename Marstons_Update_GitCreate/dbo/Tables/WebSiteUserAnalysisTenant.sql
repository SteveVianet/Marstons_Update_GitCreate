CREATE TABLE [dbo].[WebSiteUserAnalysisTenant] (
    [WeekCommencing]         DATETIME NOT NULL,
    [BDMID]                  INT      NOT NULL,
    [LicenseeID]             INT      NOT NULL,
    [LicenseeLoginCount]     INT      CONSTRAINT [DF_WebSiteUserAnalysisTenant_LicenseeLoginCount] DEFAULT ((0)) NOT NULL,
    [LicenseeSessionAverage] INT      CONSTRAINT [DF_WebSiteUserAnalysisTenant_LicenseeSessionAverage] DEFAULT ((0)) NOT NULL,
    [LicenseePagesAccessed]  INT      CONSTRAINT [DF_WebSiteUserAnalysisTenant_LicenseePagesAccessed] DEFAULT ((0)) NOT NULL
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_TenantUsers_WeekCommencing_BDMID_LicenseeID]
    ON [dbo].[WebSiteUserAnalysisTenant]([WeekCommencing] ASC, [BDMID] ASC, [LicenseeID] ASC);

