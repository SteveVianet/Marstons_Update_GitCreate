

CREATE PROCEDURE GetAuditExceptionConfiguration
AS
SELECT  RunClosedWithDelivery,
		RunTampering,
		RunNoWater,
		RunNotDownloading,
		RunEDISTimeOut,
		RunMissingShadowRAM,
		RunMissingData,
		RunFontSetupsToAction,
		RunCallOnHold,
		RunNewProductKeg,
		RunNewProductCask,
		RunStoppedLines,
		RunCalibrationIssue,
		RunTrafficLightChange,
		RunNotAuditedInThreeWeeks
FROM AuditExceptionConfiguration


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetAuditExceptionConfiguration] TO PUBLIC
    AS [dbo];

