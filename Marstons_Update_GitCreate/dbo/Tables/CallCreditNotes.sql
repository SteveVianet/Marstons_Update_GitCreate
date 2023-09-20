CREATE TABLE [dbo].[CallCreditNotes] (
    [CallID]            INT            NOT NULL,
    [TotalVolume]       INT            NOT NULL,
    [Reason]            VARCHAR (255)  NOT NULL,
    [CreditDate]        DATETIME       NOT NULL,
    [LicenseeName]      VARCHAR (50)   NOT NULL,
    [LicenseeSignature] VARCHAR (1500) NOT NULL,
    [DateProcessed]     DATETIME       NULL,
    [SignatureBase64]   VARCHAR (MAX)  NULL,
    PRIMARY KEY CLUSTERED ([CallID] ASC),
    FOREIGN KEY ([CallID]) REFERENCES [dbo].[Calls] ([ID])
);

