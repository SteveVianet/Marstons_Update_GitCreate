CREATE TABLE [dbo].[CallBillingItems] (
    [CallID]          INT        NOT NULL,
    [BillingItemID]   INT        NOT NULL,
    [Quantity]        INT        NOT NULL,
    [FullCostPrice]   MONEY      NOT NULL,
    [FullRetailPrice] MONEY      NOT NULL,
    [VAT]             FLOAT (53) NOT NULL,
    [ContractID]      INT        NOT NULL,
    [LabourMinutes]   FLOAT (53) DEFAULT ((0)) NOT NULL,
    [IsCharged]       BIT        DEFAULT ((1)) NOT NULL,
    [LabourTypeID]    INT        DEFAULT ((0)) NOT NULL,
    [ContractPrice]   FLOAT (53) NULL,
    CONSTRAINT [PK_CallBillingItems] PRIMARY KEY CLUSTERED ([CallID] ASC, [BillingItemID] ASC)
);

