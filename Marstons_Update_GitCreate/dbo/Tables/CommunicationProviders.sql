CREATE TABLE [dbo].[CommunicationProviders] (
    [ID]           INT          IDENTITY (1, 1) NOT NULL,
    [ProviderName] VARCHAR (50) NOT NULL,
    CONSTRAINT [PK_CommunicationProviders] PRIMARY KEY CLUSTERED ([ID] ASC)
);

