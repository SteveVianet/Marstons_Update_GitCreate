CREATE TABLE [dbo].[CallReasonTypes] (
    [CallReasonTypeID]      INT NOT NULL,
    [ContractID]            INT NOT NULL,
    [PriorityID]            INT NULL,
    [FlagToFinance]         BIT NULL,
    [SLA]                   INT NULL,
    [AuthorisationRequired] BIT NULL,
    [SLAForKeyTap]          INT NULL,
    CONSTRAINT [PK_CallReasonTypes] PRIMARY KEY CLUSTERED ([CallReasonTypeID] ASC, [ContractID] ASC),
    CONSTRAINT [FK_CallReasonTypes_Contracts] FOREIGN KEY ([ContractID]) REFERENCES [dbo].[Contracts] ([ID])
);

