CREATE TABLE [dbo].[AuditExceptions] (
    [EDISID]                    INT            NOT NULL,
    [ValidTo]                   DATETIME       NULL,
    [Tampering]                 BIT            NOT NULL,
    [NoWater]                   BIT            NOT NULL,
    [NotDownloading]            BIT            NOT NULL,
    [EDISTimeOut]               BIT            NOT NULL,
    [MissingShadowRAM]          BIT            NOT NULL,
    [MissingData]               BIT            NOT NULL,
    [FontSetupsToAction]        BIT            NOT NULL,
    [CallOnHold]                BIT            NOT NULL,
    [NotAuditedInThreeWeeks]    BIT            NOT NULL,
    [StoppedLines]              BIT            NOT NULL,
    [CalibrationIssue]          BIT            NOT NULL,
    [NewProductKeg]             BIT            NOT NULL,
    [NewProductCask]            BIT            NOT NULL,
    [ClosedWithDelivery]        BIT            NOT NULL,
    [TrafficLightColour]        INT            DEFAULT ((3)) NOT NULL,
    [TrafficLightFailReason]    VARCHAR (4000) NULL,
    [RefreshedBy]               VARCHAR (100)  NULL,
    [RefreshedAllSites]         BIT            NULL,
    [From]                      DATETIME       NULL,
    [To]                        DATETIME       NULL,
    [RefreshedOn]               DATETIME       NULL,
    [CurrentTrafficLightColour] INT            NULL,
    [StoppedLineReasons]        VARCHAR (4000) NULL,
    [CalibrationIssueReasons]   VARCHAR (4000) NULL,
    [NewProductKegReasons]      VARCHAR (4000) NULL,
    [NewProductCaskReasons]     VARCHAR (4000) NULL,
    [ClosedOrMissingShadowRAM]  BIT            CONSTRAINT [DF_AuditExceptions_ClosedOrMissingShadowRAM] DEFAULT ((0)) NOT NULL
);


GO
CREATE NONCLUSTERED INDEX [missing_index_2350_2349_AuditExceptions]
    ON [dbo].[AuditExceptions]([ValidTo] ASC)
    INCLUDE([EDISID], [Tampering], [NoWater], [NotDownloading], [EDISTimeOut], [MissingShadowRAM], [MissingData], [FontSetupsToAction], [CallOnHold], [NotAuditedInThreeWeeks], [StoppedLines], [CalibrationIssue], [NewProductKeg], [NewProductCask], [ClosedWithDelivery], [TrafficLightColour], [TrafficLightFailReason], [From], [To], [RefreshedOn], [CurrentTrafficLightColour], [StoppedLineReasons], [CalibrationIssueReasons], [NewProductKegReasons], [NewProductCaskReasons], [ClosedOrMissingShadowRAM]);


GO
CREATE NONCLUSTERED INDEX [IX_AuditExceptions_EDISID_ValidTo]
    ON [dbo].[AuditExceptions]([EDISID] ASC)
    INCLUDE([ValidTo]);

