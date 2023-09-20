CREATE TABLE [dbo].[InvoiceItems] (
    [CallID]   INT        NOT NULL,
    [ItemID]   INT        NOT NULL,
    [Quantity] FLOAT (53) NOT NULL,
    [Cost]     MONEY      NULL,
    [VAT]      FLOAT (53) NULL,
    CONSTRAINT [PK_InvoiceItems] PRIMARY KEY CLUSTERED ([CallID] ASC, [ItemID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_InvoiceItems_Calls] FOREIGN KEY ([CallID]) REFERENCES [dbo].[Calls] ([ID])
);

