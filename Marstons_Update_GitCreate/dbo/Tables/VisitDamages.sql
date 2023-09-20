CREATE TABLE [dbo].[VisitDamages] (
    [DamagesID]             INT             IDENTITY (1, 1) NOT NULL,
    [VisitRecordID]         INT             NOT NULL,
    [DamagesType]           INT             NOT NULL,
    [Product]               NVARCHAR (50)   NULL,
    [ReportedDraughtVolume] NUMERIC (10, 2) NULL,
    [CalCheck]              INT             NULL,
    [DraughtVolume]         NUMERIC (10, 2) CONSTRAINT [DF_VisitDamages_DraughtVolumeConfirmed] DEFAULT (0) NULL,
    [Cases]                 INT             NULL,
    [Bottles]               INT             NULL,
    [Damages]               NUMERIC (10, 2) CONSTRAINT [DF_VisitDamages_DamagesConfirmed] DEFAULT (0) NULL,
    [Agreed]                BIT             NULL,
    [DraughtStock]          NUMERIC (10, 2) CONSTRAINT [DF_VisitDamages_DraughtStock] DEFAULT (0) NULL,
    [Comment]               NVARCHAR (2000) NULL,
    CONSTRAINT [PK_VisitDamages] PRIMARY KEY CLUSTERED ([DamagesID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_VisitDamages_VisitID]
    ON [dbo].[VisitDamages]([VisitRecordID] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_VisitDamages_Type]
    ON [dbo].[VisitDamages]([VisitRecordID] ASC, [DamagesType] ASC);

