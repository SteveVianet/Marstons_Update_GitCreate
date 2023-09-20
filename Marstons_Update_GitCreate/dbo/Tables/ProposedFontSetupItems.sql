﻿CREATE TABLE [dbo].[ProposedFontSetupItems] (
    [ProposedFontSetupID]      INT            NOT NULL,
    [FontNumber]               INT            NOT NULL,
    [Product]                  VARCHAR (1024) NOT NULL,
    [Location]                 VARCHAR (1024) NOT NULL,
    [InUse]                    BIT            NOT NULL,
    [JobType]                  INT            CONSTRAINT [DF_ProposedFontSetupItems_JobType] DEFAULT (0) NOT NULL,
    [zzzGlassID]               INT            NULL,
    [Version]                  INT            NULL,
    [PhysicalAddress]          INT            NULL,
    [StockValue]               FLOAT (53)     NULL,
    [NewCalibrationValue]      INT            NULL,
    [OriginalCalibrationValue] INT            NULL,
    [DispenseEquipmentTypeID]  INT            CONSTRAINT [DF_ProposedFontSetupItems_MeterReplacement] DEFAULT (0) NOT NULL,
    [CalibratedOnWater]        BIT            CONSTRAINT [DF_ProposedFontSetupItems_CalibratedOnWater] DEFAULT (0) NOT NULL,
    [GlasswareID]              NVARCHAR (50)  NULL,
    [DispenseProductType]      INT            DEFAULT (1) NOT NULL,
    [CalibrationIssueType]     INT            DEFAULT (1) NOT NULL,
    [Calibrated]               BIT            DEFAULT (0) NOT NULL,
    [DispenseEquipmentType]    INT            DEFAULT (1) NOT NULL,
    [CalibrationChangeType]    INT            DEFAULT ((1)) NOT NULL,
    [Review]                   BIT            DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_ProposedFontSetupItems] PRIMARY KEY CLUSTERED ([ProposedFontSetupID] ASC, [FontNumber] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_ProposedFontSetupItems_ProposedFontSetupID] FOREIGN KEY ([ProposedFontSetupID]) REFERENCES [dbo].[ProposedFontSetups] ([ID])
);
