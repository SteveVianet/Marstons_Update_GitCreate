CREATE TABLE [dbo].[Calls] (
    [ID]                     INT           IDENTITY (1, 1) NOT NULL,
    [EDISID]                 INT           NOT NULL,
    [CallTypeID]             INT           CONSTRAINT [DF_Calls_CallTypeID] DEFAULT (1) NOT NULL,
    [RaisedOn]               DATETIME      CONSTRAINT [DF_Calls_RaisedOn] DEFAULT (getdate()) NOT NULL,
    [RaisedBy]               VARCHAR (255) CONSTRAINT [DF_Calls_RaisedBy] DEFAULT (suser_sname()) NOT NULL,
    [ReportedBy]             VARCHAR (255) NOT NULL,
    [EngineerID]             INT           NULL,
    [ContractorReference]    VARCHAR (255) NULL,
    [PriorityID]             INT           NOT NULL,
    [POConfirmed]            DATETIME      NULL,
    [VisitedOn]              DATETIME      NULL,
    [ClosedOn]               DATETIME      NULL,
    [ClosedBy]               VARCHAR (255) NULL,
    [SignedBy]               VARCHAR (255) NULL,
    [AuthCode]               VARCHAR (255) NULL,
    [POStatusID]             INT           NOT NULL,
    [SalesReference]         VARCHAR (255) NULL,
    [InvoicedOn]             DATETIME      NULL,
    [InvoicedBy]             VARCHAR (255) NULL,
    [WorkDetailComment]      TEXT          NULL,
    [AbortReasonID]          INT           DEFAULT (0) NOT NULL,
    [AbortDate]              DATETIME      NULL,
    [AbortUser]              VARCHAR (255) NULL,
    [AbortCode]              VARCHAR (255) NULL,
    [CustomerAbortCode]      VARCHAR (255) NULL,
    [TelecomReference]       VARCHAR (255) NULL,
    [DaysOnHold]             INT           DEFAULT (0) NOT NULL,
    [OverrideSLA]            INT           DEFAULT (0) NOT NULL,
    [IsChargeable]           BIT           DEFAULT ((0)) NOT NULL,
    [NumberOfVisits]         INT           DEFAULT ((1)) NOT NULL,
    [VisitStartedOn]         DATETIME      NULL,
    [VisitEndedOn]           DATETIME      NULL,
    [PlanningIssueID]        INT           DEFAULT ((1)) NOT NULL,
    [ReRaiseFromCallID]      INT           NULL,
    [CallCategoryID]         INT           DEFAULT ((1)) NOT NULL,
    [QualitySite]            BIT           DEFAULT ((0)) NOT NULL,
    [InstallationDate]       DATETIME      NULL,
    [RequestID]              INT           DEFAULT ((1)) NOT NULL,
    [FlagToFinance]          BIT           DEFAULT ((1)) NOT NULL,
    [IncompleteReasonID]     INT           DEFAULT ((0)) NOT NULL,
    [IncompleteDate]         DATETIME      NULL,
    [AuthorisationRequired]  BIT           DEFAULT ((0)) NOT NULL,
    [ContractID]             INT           NULL,
    [UseBillingItems]        BIT           DEFAULT ((0)) NOT NULL,
    [CreditDate]             DATETIME      NULL,
    [CreditAmount]           MONEY         NULL,
    [StandardLabourCharge]   MONEY         DEFAULT ((0)) NOT NULL,
    [AdditionalLabourCharge] MONEY         DEFAULT ((0)) NOT NULL,
    [ChargeReasonID]         INT           DEFAULT ((0)) NOT NULL,
    [InstallCallID]          INT           NULL,
    CONSTRAINT [PK_Calls] PRIMARY KEY CLUSTERED ([ID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Calls_Sites] FOREIGN KEY ([EDISID]) REFERENCES [dbo].[Sites] ([EDISID])
);


GO
CREATE NONCLUSTERED INDEX [IX_Calls_RaisedOn_EDISID]
    ON [dbo].[Calls]([RaisedOn] ASC, [EDISID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [missing_index_473627_473626_Calls]
    ON [dbo].[Calls]([VisitedOn] ASC)
    INCLUDE([ID], [EDISID]);

