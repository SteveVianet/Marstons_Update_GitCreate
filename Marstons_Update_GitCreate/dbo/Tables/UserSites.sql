CREATE TABLE [dbo].[UserSites] (
    [UserID]  INT          NOT NULL,
    [EDISID]  INT          NOT NULL,
    [AddedOn] DATETIME     CONSTRAINT [DF_UserSites_AddedOn] DEFAULT (getdate()) NOT NULL,
    [AddedBy] VARCHAR (50) CONSTRAINT [DF_UserSites_AddedBy] DEFAULT (suser_name()) NOT NULL,
    CONSTRAINT [PK_UserSites] PRIMARY KEY CLUSTERED ([UserID] ASC, [EDISID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_UserSites_Sites] FOREIGN KEY ([EDISID]) REFERENCES [dbo].[Sites] ([EDISID]) ON DELETE CASCADE,
    CONSTRAINT [FK_UserSites_Users] FOREIGN KEY ([UserID]) REFERENCES [dbo].[Users] ([ID]) ON DELETE CASCADE
);


GO
CREATE NONCLUSTERED INDEX [IX_UserSites_EDISID]
    ON [dbo].[UserSites]([EDISID] ASC)
    INCLUDE([UserID]);


GO
CREATE NONCLUSTERED INDEX [IX_UserSites_UserID]
    ON [dbo].[UserSites]([UserID] ASC)
    INCLUDE([EDISID]);

