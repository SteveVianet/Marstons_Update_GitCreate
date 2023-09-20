CREATE TABLE [dbo].[SiteScorecardEmails] (
    [ID]              INT      IDENTITY (1, 1) NOT NULL,
    [EDISID]          INT      NOT NULL,
    [Date]            DATETIME NOT NULL,
    [HTMLString]      TEXT     NULL,
    [Processed]       BIT      CONSTRAINT [DF_SiteScorecardEmails_Processed] DEFAULT ((0)) NOT NULL,
    [RecipientUserID] INT      NOT NULL,
    CONSTRAINT [PK_SiteScorecardEmails] PRIMARY KEY CLUSTERED ([ID] ASC)
);

