CREATE TABLE [dbo].[ContractFreeItems] (
    [ContractID] INT NOT NULL,
    [ItemID]     INT NOT NULL,
    CONSTRAINT [PK_ContractFreeItems] PRIMARY KEY CLUSTERED ([ContractID] ASC, [ItemID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_ContractFreeItems_Contracts] FOREIGN KEY ([ContractID]) REFERENCES [dbo].[Contracts] ([ID])
);

