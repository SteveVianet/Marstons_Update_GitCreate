﻿CREATE TABLE [dbo].[CallCompletionSheets] (
    [CallID]                INT            NOT NULL,
    [FontsWork]             BIT            NOT NULL,
    [CellarClean]           BIT            NOT NULL,
    [PowerDisruption]       BIT            NOT NULL,
    [MinorWorksCertificate] BIT            NOT NULL,
    [CreditNoteIssued]      BIT            NOT NULL,
    [Calibration]           BIT            NOT NULL,
    [Verification]          BIT            NOT NULL,
    [Uplift]                BIT            NOT NULL,
    [Cooling]               BIT            NOT NULL,
    [CreditRequired]        BIT            NOT NULL,
    [TotalVolumeDispensed]  INT            NOT NULL,
    [LicenseeName]          VARCHAR (255)  NOT NULL,
    [LicenseeSignature]     VARCHAR (1500) NOT NULL,
    [SignatureDate]         DATETIME       NULL,
    [FlowmetersUsed]        INT            NOT NULL,
    [FlowmetersRemoved]     INT            NOT NULL,
    [CheckValvesUsed]       INT            NOT NULL,
    [CheckValvesRemoved]    INT            NOT NULL,
    [WorkCarriedOut]        VARCHAR (255)  NOT NULL,
    [TimeOnSite]            INT            NOT NULL,
    [SignatureBase64]       VARCHAR (MAX)  NULL,
    PRIMARY KEY CLUSTERED ([CallID] ASC),
    FOREIGN KEY ([CallID]) REFERENCES [dbo].[Calls] ([ID])
);

