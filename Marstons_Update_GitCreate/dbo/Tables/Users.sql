CREATE TABLE [dbo].[Users] (
    [ID]                        INT           IDENTITY (1, 1) NOT NULL,
    [UserName]                  VARCHAR (255) NOT NULL,
    [Login]                     VARCHAR (255) NOT NULL,
    [Password]                  VARCHAR (255) NOT NULL,
    [UserType]                  INT           NOT NULL,
    [EMail]                     VARCHAR (255) NOT NULL,
    [PhoneNumber]               VARCHAR (255) DEFAULT ('') NOT NULL,
    [CreatedBy]                 VARCHAR (255) CONSTRAINT [DF_Users_CreatedBy] DEFAULT (suser_sname()) NOT NULL,
    [CreatedOn]                 DATETIME      CONSTRAINT [DF_Users_CreatedOn] DEFAULT (getdate()) NOT NULL,
    [Deleted]                   BIT           CONSTRAINT [DF_Users_Deleted] DEFAULT (0) NOT NULL,
    [WebActive]                 BIT           CONSTRAINT [DF_Users_WebActive] DEFAULT (1) NOT NULL,
    [LastWebsiteLoginDate]      DATETIME      CONSTRAINT [DF_Users_LastWebsiteLoginDate] DEFAULT (getdate()) NOT NULL,
    [LastWebsiteLoginIPAddress] VARCHAR (255) NULL,
    [NeverExpire]               BIT           CONSTRAINT [DF__Users__NeverExpi__7D8391DF] DEFAULT (1) NULL,
    [VRSUserID]                 BIGINT        NULL,
    [Anonymise]                 BIT           DEFAULT (0) NOT NULL,
    [SendEMailAlert]            BIT           DEFAULT (0) NOT NULL,
    [SendSMSAlert]              BIT           DEFAULT (0) NOT NULL,
    [LanguageOverride]          VARCHAR (20)  NULL,
    [AcceptedDisclaimer]        BIT           DEFAULT ((0)) NOT NULL,
    [ReceiveNewCDAlert]         BIT           DEFAULT ((0)) NOT NULL,
    [ReceiveiDraughtScorecard]  BIT           DEFAULT ((0)) NOT NULL,
    [DetailsReviewedOn]         DATETIME      NULL,
    CONSTRAINT [PK_Users] PRIMARY KEY CLUSTERED ([ID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Users_UserTypes] FOREIGN KEY ([UserType]) REFERENCES [dbo].[UserTypes] ([ID]) ON DELETE CASCADE,
    CONSTRAINT [UX_Users] UNIQUE NONCLUSTERED ([Login] ASC) WITH (FILLFACTOR = 90)
);


GO
CREATE NONCLUSTERED INDEX [IX_Users_UserType]
    ON [dbo].[Users]([UserType] ASC)
    INCLUDE([ID]);


GO
CREATE NONCLUSTERED INDEX [IX_Users_Web]
    ON [dbo].[Users]([Anonymise] ASC, [ID] ASC, [Deleted] ASC, [WebActive] ASC)
    INCLUDE([UserName]);


GO
CREATE NONCLUSTERED INDEX [IX_Users_VRSUserID]
    ON [dbo].[Users]([VRSUserID] ASC);

