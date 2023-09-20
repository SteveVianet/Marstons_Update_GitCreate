CREATE TABLE [dbo].[SiteMaintenance] (
    [ID]                 INT           IDENTITY (1, 1) NOT NULL,
    [EDISID]             INT           NOT NULL,
    [PowerSupplyType]    INT           NOT NULL,
    [AccountLive]        DATE          NOT NULL,
    [PanelLive]          DATE          NOT NULL,
    [ContractStart]      DATE          NOT NULL,
    [LatestInstallation] DATE          NOT NULL,
    [LatestMaintenance]  DATE          NULL,
    [LatestPAT]          DATE          NULL,
    [LatestCalibration]  DATE          NULL,
    [MaintenanceDue]     DATE          NOT NULL,
    [MinorWorksStatus]   INT           CONSTRAINT [DF_SiteMaintenance_MinorWorksStatus] DEFAULT ((0)) NOT NULL,
    [KeyItemsCalibrated] INT           NOT NULL,
    [EngineerID]         INT           NULL,
    [DateUpdated]        DATE          CONSTRAINT [DF_SiteMaintenance_DateUpdated] DEFAULT (getdate()) NOT NULL,
    [UpdatedBy]          VARCHAR (150) CONSTRAINT [DF_SiteMaintenance_UpdatedBy] DEFAULT (suser_sname()) NOT NULL,
    [Historic]           BIT           CONSTRAINT [DF_SiteMaintenance_Historic] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_SiteMaintenance] PRIMARY KEY CLUSTERED ([ID] ASC)
);

