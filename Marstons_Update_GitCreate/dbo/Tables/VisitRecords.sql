﻿CREATE TABLE [dbo].[VisitRecords] (
    [ID]                             INT            IDENTITY (1, 1) NOT NULL,
    [CAMID]                          INT            NOT NULL,
    [FormSaved]                      DATETIME       NOT NULL,
    [CustomerID]                     INT            NULL,
    [EDISID]                         INT            NOT NULL,
    [VisitDate]                      DATETIME       NOT NULL,
    [VisitTime]                      DATETIME       NOT NULL,
    [JointVisit]                     NVARCHAR (255) NULL,
    [VisitReasonID]                  INT            NOT NULL,
    [AccessDetailsID]                INT            NOT NULL,
    [MetOnSiteID]                    INT            NOT NULL,
    [OtherMeetingLocation]           VARCHAR (255)  NULL,
    [PersonMet]                      VARCHAR (50)   NULL,
    [CompletedChecksID]              INT            NULL,
    [VerificationID]                 INT            NULL,
    [TamperingID]                    INT            NULL,
    [TamperingEvidenceID]            INT            NULL,
    [ReportFrom]                     DATETIME       NULL,
    [ReportTo]                       DATETIME       NULL,
    [ReportDetails]                  TEXT           NULL,
    [TotalStock]                     TEXT           NULL,
    [AdditionalDetails]              TEXT           NULL,
    [FurtherDiscussion]              TEXT           NULL,
    [AdmissionID]                    INT            NOT NULL,
    [AdmissionMadeByID]              INT            NOT NULL,
    [AdmissionMadeByPerson]          VARCHAR (50)   NULL,
    [AdmissionReasonID]              INT            NOT NULL,
    [AdmissionForID]                 INT            NOT NULL,
    [UTLLOU]                         BIT            CONSTRAINT [DF__VisitReco__UTLLO__6BD9E2F0] DEFAULT (0) NULL,
    [SuggestedDamagesValue]          MONEY          NULL,
    [DamagesObtained]                BIT            CONSTRAINT [DF__VisitReco__Damag__6CCE0729] DEFAULT (0) NULL,
    [DamagesObtainedValue]           MONEY          NULL,
    [DamagesExplaination]            TEXT           NULL,
    [VisitOutcomeID]                 INT            NOT NULL,
    [FurtherActionID]                INT            NOT NULL,
    [FurtherAction]                  VARCHAR (1024) NULL,
    [BDMID]                          INT            NULL,
    [BDMCommentDate]                 DATETIME       NULL,
    [BDMComment]                     TEXT           NULL,
    [Actioned]                       BIT            CONSTRAINT [DF__VisitReco__Actio__7933DE0E] DEFAULT (0) NOT NULL,
    [Injunction]                     BIT            CONSTRAINT [DF_VisitRecords_Injunction] DEFAULT (0) NOT NULL,
    [BDMUTLLOU]                      BIT            CONSTRAINT [DF_VisitRecords_BDMUTLLOU] DEFAULT (0) NOT NULL,
    [BDMDamagesIssued]               BIT            CONSTRAINT [DF_VisitRecords_BDMDamagesIssued] DEFAULT (0) NOT NULL,
    [BDMDamagesIssuedValue]          MONEY          CONSTRAINT [DF_VisitRecords_BDMDamagesIssuedValue] DEFAULT (0) NOT NULL,
    [SpecificOutcomeID]              INT            NULL,
    [ClosedByCAM]                    BIT            NULL,
    [DamagesStatus]                  INT            NULL,
    [VerballyAgressive]              BIT            NULL,
    [PhysicallyAgressive]            BIT            NULL,
    [CalChecksCompletedID]           INT            NULL,
    [LastDelivery]                   DATETIME       NULL,
    [NextDelivery]                   DATETIME       NULL,
    [StockAgreedByID]                INT            NULL,
    [DateSubmitted]                  DATETIME       NULL,
    [VerifiedByVRS]                  BIT            NULL,
    [VerifiedDate]                   DATETIME       NULL,
    [CompletedByCustomer]            BIT            NULL,
    [CompletedDate]                  DATETIME       NULL,
    [BDMActionTaken]                 INT            NULL,
    [BDMPartialReason]               TEXT           NULL,
    [DraughtDamagesTotalValue]       MONEY          NULL,
    [DraughtDamagesTotalAgreedValue] MONEY          NULL,
    [ResendEmailOn]                  DATETIME       NULL,
    [Deleted]                        BIT            NULL,
    [PhysicalEvidenceOfBuyingOut]    BIT            NULL,
    [ComplianceAudit]                BIT            NULL,
    CONSTRAINT [PK__VisitRecords__6AE5BEB7] PRIMARY KEY CLUSTERED ([ID] ASC),
    CONSTRAINT [FK_VisitRecord_Sites] FOREIGN KEY ([EDISID]) REFERENCES [dbo].[Sites] ([EDISID]),
    CONSTRAINT [FK_VisitRecords_Users_BDMID] FOREIGN KEY ([BDMID]) REFERENCES [dbo].[Users] ([ID])
);


GO
CREATE NONCLUSTERED INDEX [missing_index_683_682_VisitRecords]
    ON [dbo].[VisitRecords]([CustomerID] ASC, [EDISID] ASC, [Deleted] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_VisitRecord_Summary]
    ON [dbo].[VisitRecords]([CAMID] ASC, [CustomerID] ASC, [Deleted] ASC, [VerifiedByVRS] ASC, [CompletedByCustomer] ASC)
    INCLUDE([ID], [FormSaved], [EDISID], [VisitDate], [ClosedByCAM], [DateSubmitted]);

