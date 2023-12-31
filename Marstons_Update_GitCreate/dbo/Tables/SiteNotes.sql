﻿CREATE TABLE [dbo].[SiteNotes] (
    [ID]                 INT        IDENTITY (1, 1) NOT NULL,
    [EDISID]             INT        NOT NULL,
    [BuyingOut]          BIT        CONSTRAINT [DF_SiteNotes_BuyingOut] DEFAULT (0) NOT NULL,
    [ActionID]           INT        CONSTRAINT [DF_SiteNotes_ActionID] DEFAULT (0) NOT NULL,
    [OutcomeID]          INT        CONSTRAINT [DF_SiteNotes_OutcomeID] DEFAULT (0) NOT NULL,
    [BDMActionRequired]  BIT        CONSTRAINT [DF_SiteNotes_BDMActionRequired] DEFAULT (0) NOT NULL,
    [BDMActioned]        BIT        CONSTRAINT [DF_SiteNotes_BDMActioned] DEFAULT (0) NOT NULL,
    [Undertaking]        BIT        CONSTRAINT [DF_SiteNotes_Undertaking] DEFAULT (0) NOT NULL,
    [Injunction]         BIT        CONSTRAINT [DF_SiteNotes_Injunction] DEFAULT (0) NOT NULL,
    [Liquidated]         BIT        CONSTRAINT [DF_SiteNotes_Liquidated] DEFAULT (0) NOT NULL,
    [Value]              FLOAT (53) CONSTRAINT [DF_SiteNotes_Value] DEFAULT (0) NOT NULL,
    [TheVisit]           TEXT       NOT NULL,
    [Discussions]        TEXT       NOT NULL,
    [Evidence]           TEXT       NOT NULL,
    [TradingPatterns]    TEXT       NOT NULL,
    [FurtherDiscussions] TEXT       NOT NULL,
    [BuyingOutLevel]     TEXT       NOT NULL,
    [CourseOfAction]     TEXT       NOT NULL,
    [UserID]             INT        NOT NULL,
    [Date]               DATETIME   CONSTRAINT [DF_SiteNotes_Date] DEFAULT (getdate()) NOT NULL,
    [BDMUserID]          INT        NULL,
    [BDMComment]         TEXT       NULL,
    [BDMDate]            DATETIME   NULL,
    [TrackingDate]       DATETIME   CONSTRAINT [DF_SiteNotes_TrackingDate] DEFAULT (0) NOT NULL,
    [Confirmed]          BIT        NULL,
    [RobustAction]       BIT        DEFAULT (0) NOT NULL,
    [Cleared]            BIT        DEFAULT (0) NOT NULL,
    CONSTRAINT [PK_SiteNotes] PRIMARY KEY CLUSTERED ([ID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_SiteNotes_Users_BDMUserID] FOREIGN KEY ([BDMUserID]) REFERENCES [dbo].[Users] ([ID]),
    CONSTRAINT [FK_SiteNotes_Users_UserID] FOREIGN KEY ([UserID]) REFERENCES [dbo].[Users] ([ID]),
    CONSTRAINT [FK_SiteNotes_VRSActions] FOREIGN KEY ([ActionID]) REFERENCES [dbo].[VRSActions] ([ID]) ON DELETE CASCADE,
    CONSTRAINT [FK_SiteNotes_VRSOutcomes] FOREIGN KEY ([OutcomeID]) REFERENCES [dbo].[VRSOutcomes] ([ID]) ON DELETE CASCADE,
    CONSTRAINT [UX_SiteNotes_EDISID_Date] UNIQUE NONCLUSTERED ([EDISID] ASC, [Date] ASC) WITH (FILLFACTOR = 90)
);

