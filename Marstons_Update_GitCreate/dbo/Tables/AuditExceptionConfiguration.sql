CREATE TABLE [dbo].[AuditExceptionConfiguration] (
    [RunClosedWithDelivery]                 BIT DEFAULT ((1)) NOT NULL,
    [RunTampering]                          BIT DEFAULT ((1)) NOT NULL,
    [RunNoWater]                            BIT DEFAULT ((1)) NOT NULL,
    [RunNotDownloading]                     BIT DEFAULT ((1)) NOT NULL,
    [RunEDISTimeOut]                        BIT DEFAULT ((1)) NOT NULL,
    [RunMissingShadowRAM]                   BIT DEFAULT ((1)) NOT NULL,
    [RunMissingData]                        BIT DEFAULT ((1)) NOT NULL,
    [RunFontSetupsToAction]                 BIT DEFAULT ((1)) NOT NULL,
    [RunCallOnHold]                         BIT DEFAULT ((1)) NOT NULL,
    [RunNewProductKeg]                      BIT DEFAULT ((1)) NOT NULL,
    [RunNewProductCask]                     BIT DEFAULT ((1)) NOT NULL,
    [RunStoppedLines]                       BIT DEFAULT ((1)) NOT NULL,
    [RunCalibrationIssue]                   BIT DEFAULT ((1)) NOT NULL,
    [RunTrafficLightChange]                 BIT DEFAULT ((1)) NOT NULL,
    [RunNotAuditedInThreeWeeks]             BIT DEFAULT ((1)) NOT NULL,
    [NotAuditedForWeeks]                    INT DEFAULT ((3)) NOT NULL,
    [TrafficLightProductVarianceMultiplier] INT DEFAULT ((3)) NOT NULL
);

