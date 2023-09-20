CREATE TABLE [dbo].[ContractLinkedBillingItems] (
    [ContractID]          INT NOT NULL,
    [BillingItemID]       INT NOT NULL,
    [LinkedBillingItemID] INT NOT NULL,
    CONSTRAINT [PK_ContractLinkedBillingItems] PRIMARY KEY CLUSTERED ([ContractID] ASC, [BillingItemID] ASC, [LinkedBillingItemID] ASC),
    CONSTRAINT [FK_ContractLinkedBillingItems_Contracts] FOREIGN KEY ([ContractID]) REFERENCES [dbo].[Contracts] ([ID])
);

