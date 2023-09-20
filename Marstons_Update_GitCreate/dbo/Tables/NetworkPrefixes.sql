CREATE TABLE [dbo].[NetworkPrefixes] (
    [ID]          INT          IDENTITY (1, 1) NOT NULL,
    [Prefix]      NVARCHAR (5) NOT NULL,
    [ModemTypeID] INT          NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

