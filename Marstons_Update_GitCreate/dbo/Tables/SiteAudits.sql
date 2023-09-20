CREATE TABLE [dbo].[SiteAudits] (
    [EDISID]    INT           NOT NULL,
    [UserName]  VARCHAR (255) CONSTRAINT [DF_SiteAudits2_UserName] DEFAULT (suser_sname()) NOT NULL,
    [TimeStamp] DATETIME      CONSTRAINT [DF_SiteAudits2_TimeStamp] DEFAULT (getdate()) NOT NULL,
    [Comment]   TEXT          NOT NULL,
    [AuditType] INT           DEFAULT (1) NOT NULL,
    CONSTRAINT [PK_SiteAudits2] PRIMARY KEY NONCLUSTERED ([EDISID] ASC, [TimeStamp] ASC),
    CONSTRAINT [FK_SiteAudits2_EDISID] FOREIGN KEY ([EDISID]) REFERENCES [dbo].[Sites] ([EDISID]) ON DELETE CASCADE
);


GO
CREATE CLUSTERED INDEX [IX_SiteAudits2_EDISID_TimeStamp]
    ON [dbo].[SiteAudits]([EDISID] ASC, [TimeStamp] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_SiteAudits2_EDISID]
    ON [dbo].[SiteAudits]([EDISID] ASC);


GO
CREATE NONCLUSTERED INDEX [missing_index_2943_2942_SiteAudits]
    ON [dbo].[SiteAudits]([TimeStamp] ASC, [AuditType] ASC)
    INCLUDE([UserName]);

