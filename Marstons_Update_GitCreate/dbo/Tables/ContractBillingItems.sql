CREATE TABLE [dbo].[ContractBillingItems] (
    [ContractID]          INT        NOT NULL,
    [BillingItemID]       INT        NOT NULL,
    [IsCharged]           BIT        NOT NULL,
    [BMSRetailPrice]      MONEY      NOT NULL,
    [IDraughtRetailPrice] MONEY      NOT NULL,
    [LabourTypeID]        INT        NULL,
    [LabourMinutes]       INT        NULL,
    [LabourCharge]        FLOAT (53) NULL,
    [PartsCharge]         FLOAT (53) NULL,
    CONSTRAINT [PK_ContractBillingItems] PRIMARY KEY CLUSTERED ([ContractID] ASC, [BillingItemID] ASC),
    CONSTRAINT [FK_ContractBillingItems_Contracts] FOREIGN KEY ([ContractID]) REFERENCES [dbo].[Contracts] ([ID])
);

