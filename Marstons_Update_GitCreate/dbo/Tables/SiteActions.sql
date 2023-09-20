CREATE TABLE [dbo].[SiteActions] (
    [EDISID]    INT           NOT NULL,
    [UserName]  VARCHAR (255) CONSTRAINT [DF_SiteActions_UserName] DEFAULT (suser_sname()) NOT NULL,
    [TimeStamp] DATETIME      CONSTRAINT [DF_SiteActions_TimeStamp] DEFAULT (getdate()) NOT NULL,
    [ActionID]  INT           NOT NULL,
    CONSTRAINT [FK_SiteActions_EDISID] FOREIGN KEY ([EDISID]) REFERENCES [dbo].[Sites] ([EDISID]) ON DELETE CASCADE
);


GO
CREATE CLUSTERED INDEX [IX_SiteActions_EDISID_ActionID_TimeStamp]
    ON [dbo].[SiteActions]([EDISID] ASC, [TimeStamp] ASC, [ActionID] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_SiteActions_TimeStamp]
    ON [dbo].[SiteActions]([TimeStamp] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_SiteActions_ActionID]
    ON [dbo].[SiteActions]([ActionID] ASC);

