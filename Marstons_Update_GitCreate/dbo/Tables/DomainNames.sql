CREATE TABLE [dbo].[DomainNames] (
    [ID]     INT           IDENTITY (1, 1) NOT NULL,
    [Domain] VARCHAR (255) NOT NULL,
    CONSTRAINT [PK_DomainNames] PRIMARY KEY CLUSTERED ([ID] ASC)
);

