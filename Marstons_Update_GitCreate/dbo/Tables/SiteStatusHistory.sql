CREATE TABLE [dbo].[SiteStatusHistory] (
    [EDISID]    INT           NOT NULL,
    [StatusID]  INT           NOT NULL,
    [ValidFrom] DATETIME      NOT NULL,
    [ValidTo]   DATETIME      NULL,
    [User]      VARCHAR (100) NULL,
    CONSTRAINT [PK_SiteStatusHistory] PRIMARY KEY CLUSTERED ([EDISID] ASC, [StatusID] ASC, [ValidFrom] ASC)
);

