CREATE TABLE [dbo].[ContractChangeLog] (
    [ID]          INT            IDENTITY (1, 1) NOT NULL,
    [ItemType]    VARCHAR (100)  NOT NULL,
    [ChangeDate]  DATETIME       NOT NULL,
    [User]        VARCHAR (255)  NOT NULL,
    [ContractID]  INT            NOT NULL,
    [Description] VARCHAR (8000) NOT NULL,
    CONSTRAINT [PK_ContractChangeLog] PRIMARY KEY CLUSTERED ([ID] ASC),
    CONSTRAINT [FK_ContractChangeLog_Contracts] FOREIGN KEY ([ContractID]) REFERENCES [dbo].[Contracts] ([ID])
);

