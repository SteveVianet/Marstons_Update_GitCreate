CREATE TABLE [dbo].[ContractBillingItemsLog] (
    [ID]                     INT           IDENTITY (1, 1) NOT NULL,
    [ChangeDate]             DATETIME      NOT NULL,
    [User]                   VARCHAR (255) NOT NULL,
    [ContractID]             INT           NOT NULL,
    [BillingItemID]          INT           NOT NULL,
    [OldIsCharged]           BIT           NOT NULL,
    [OldBMSRetailPrice]      MONEY         NOT NULL,
    [OldIDraughtRetailPrice] MONEY         NOT NULL,
    CONSTRAINT [PK_ContractBillingItemsLog] PRIMARY KEY CLUSTERED ([ID] ASC)
);

