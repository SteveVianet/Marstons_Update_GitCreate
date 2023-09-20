CREATE TABLE [dbo].[ContractItemPrices] (
    [ContractID] INT      NOT NULL,
    [ItemID]     INT      NOT NULL,
    [Price]      MONEY    NOT NULL,
    [ValidTo]    DATETIME NULL,
    CONSTRAINT [PK_ContractItemPrices] PRIMARY KEY CLUSTERED ([ContractID] ASC, [ItemID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_ContractItemPrices_Contracts] FOREIGN KEY ([ContractID]) REFERENCES [dbo].[Contracts] ([ID])
);

