CREATE TABLE [dbo].[SiteExceptionEmails] (
    [ID]           INT            IDENTITY (1, 1) NOT NULL,
    [EmailSentTo]  VARCHAR (8000) NULL,
    [EmailDate]    DATETIME       NULL,
    [EmailContent] VARCHAR (MAX)  NULL,
    [EmailSubject] VARCHAR (MAX)  NULL,
    [Acknowledged] BIT            DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_SiteExceptionEmails] PRIMARY KEY CLUSTERED ([ID] ASC)
);

