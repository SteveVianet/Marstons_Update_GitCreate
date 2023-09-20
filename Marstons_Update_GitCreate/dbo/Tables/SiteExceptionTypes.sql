CREATE TABLE [dbo].[SiteExceptionTypes] (
    [ID]          INT          IDENTITY (1, 1) NOT NULL,
    [Description] VARCHAR (50) NOT NULL,
    [Rank]        INT          NOT NULL,
    CONSTRAINT [PK_SiteExceptionTypes] PRIMARY KEY CLUSTERED ([ID] ASC)
);

