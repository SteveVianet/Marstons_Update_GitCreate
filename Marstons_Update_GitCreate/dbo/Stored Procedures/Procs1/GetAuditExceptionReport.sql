CREATE PROCEDURE [dbo].[GetAuditExceptionReport]
(
	@From		DATETIME,
	@To			DATETIME
)
AS

SET NOCOUNT ON

DECLARE @MultipleAuditors AS BIT
DECLARE @EntireCustomerAuditor AS VARCHAR(255)

SELECT @MultipleAuditors = MultipleAuditors
FROM [SQL1\SQL1].ServiceLogger.dbo.EDISDatabases 
WHERE Name = DB_NAME()

IF @MultipleAuditors = 0
BEGIN
	SELECT @EntireCustomerAuditor = 'MAINGROUP\' + REPLACE(REPLACE(REPLACE(UPPER(PropertyValue), '@BRULINES.COM', ''), '@BRULINES.CO.UK', ''), '@VIANETPLC.COM', '')
	FROM Configuration
	WHERE PropertyName = 'AuditorEMail'
END
ELSE
BEGIN
	SET @EntireCustomerAuditor = NULL
END

SELECT  Configuration.PropertyValue AS CompanyName,
	SiteAuditors.Auditor,
	Users.UserName AS BDMName,
	COUNT(*) AS NumberOfSites,
	SUM(CASE WHEN SiteAudits.EDISID IS NOT NULL THEN 1 ELSE 0 END) AS Audits,
	SUM(CASE WHEN Tampering = 1 THEN 1 ELSE 0 END) AS NumberTampering,
	SUM(CASE WHEN NoWater = 1 THEN 1 ELSE 0 END) AS NumberNoWater,
	SUM(CASE WHEN NotDownloading = 1 THEN 1 ELSE 0 END) AS NumberNotDownloading,
	SUM(CASE WHEN EDISTimeOut = 1 THEN 1 ELSE 0 END) AS NumberEDISTimeOut,
	SUM(CASE WHEN MissingShadowRAM = 1 THEN 1 ELSE 0 END) AS NumberMissingShadowRAM,
	SUM(CASE WHEN MissingData = 1 THEN 1 ELSE 0 END) AS NumberMissingData,
	SUM(CASE WHEN FontSetupsToAction = 1 THEN 1 ELSE 0 END) AS NumberFontSetupsToAction,
	SUM(CASE WHEN CallOnHold = 1 THEN 1 ELSE 0 END) AS NumberCallOnHold,
	SUM(CASE WHEN NotAuditedInThreeWeeks = 1 THEN 1 ELSE 0 END) AS NumberNotAuditedInThreeWeeks,
	SUM(CASE WHEN StoppedLines = 1 THEN 1 ELSE 0 END) AS NumberStoppedLines,
	SUM(CASE WHEN CalibrationIssue = 1 THEN 1 ELSE 0 END) AS NumberCalibrationIssue,
	SUM(CASE WHEN NewProductKeg = 1 THEN 1 ELSE 0 END) AS NumberNewProductKeg,
	SUM(CASE WHEN NewProductCask = 1 THEN 1 ELSE 0 END) AS NumberNewProductCask,
	SUM(CASE WHEN ClosedWithDelivery = 1 THEN 1 ELSE 0 END) AS NumberClosedWithDelivery,
	SUM(CASE WHEN TLChange = 1 THEN 1 ELSE 0 END) AS NumberTLChange,
	SUM(CASE WHEN Tampering = 0 AND NoWater = 0 AND NotDownloading = 0 AND EDISTimeOut = 0 AND MissingShadowRAM = 0 AND MissingData = 0 AND FontSetupsToAction = 0 AND CallOnHold = 0 AND NotAuditedInThreeWeeks = 0 AND StoppedLines = 0 AND CalibrationIssue = 0 AND NewProductKeg = 0 AND NewProductCask = 0 AND ClosedWithDelivery = 0 AND TLChange = 0 THEN 1 ELSE 0 END) AS NumberNoIssueSites,
	SUM(CASE WHEN RefreshedOn < @From THEN 1 ELSE 0 END) AS SitesNotRefreshed
FROM (
	SELECT  EDISID,
			dbo.udfNiceName(ISNULL(@EntireCustomerAuditor, UPPER(SiteUser))) AS Auditor
	FROM Sites
	WHERE Hidden = 0
) AS SiteAuditors
JOIN (
	SELECT  Users.ID AS BDMID,
			Sites.EDISID
	FROM Sites
	JOIN UserSites ON UserSites.EDISID = Sites.EDISID
	JOIN Users ON Users.ID = UserSites.UserID
	WHERE Users.UserType = 2 AND Sites.Hidden = 0
) AS SiteBDMs ON SiteBDMs.EDISID = SiteAuditors.EDISID
JOIN Configuration ON Configuration.PropertyName = 'Company Name'
JOIN Users ON Users.ID = SiteBDMs.BDMID
JOIN (
	SELECT AuditExceptions.EDISID, 
		   LastManualAudits.LastAudit, 
		   CASE WHEN RunTampering = 1 THEN Tampering ELSE 0 END AS Tampering, 
		   CASE WHEN RunNoWater = 1 THEN NoWater ELSE 0 END AS NoWater, 
		   CASE WHEN RunNotDownloading = 1 THEN NotDownloading ELSE 0 END AS NotDownloading, 
		   CASE WHEN RunEDISTimeOut = 1 THEN EDISTimeOut ELSE 0 END AS EDISTimeOut,
		   CASE WHEN RunMissingShadowRAM = 1 THEN MissingShadowRAM ELSE 0 END AS MissingShadowRAM,
		   CASE WHEN RunMissingData = 1 THEN MissingData ELSE 0 END AS MissingData,
		   CASE WHEN RunFontSetupsToAction = 1 THEN FontSetupsToAction ELSE 0 END AS FontSetupsToAction,
		   CASE WHEN RunCallOnHold = 1 THEN CallOnHold ELSE 0 END AS CallOnHold,
		   CASE WHEN RunNotAuditedInThreeWeeks = 1 THEN NotAuditedInThreeWeeks ELSE 0 END AS NotAuditedInThreeWeeks,
		   CASE WHEN RunStoppedLines = 1 THEN StoppedLines ELSE 0 END AS StoppedLines,
		   CASE WHEN RunCalibrationIssue = 1 THEN CalibrationIssue ELSE 0 END AS CalibrationIssue,
		   CASE WHEN RunNewProductKeg = 1 THEN NewProductKeg ELSE 0 END AS NewProductKeg,
		   CASE WHEN RunNewProductCask = 1 THEN NewProductCask ELSE 0 END AS NewProductCask,
		   CASE WHEN RunClosedWithDelivery = 1 THEN ClosedWithDelivery ELSE 0 END AS ClosedWithDelivery,
		   CASE WHEN RunTrafficLightChange = 1 AND TrafficLightColour <> CurrentTrafficLightColour AND TrafficLightColour <= 3 THEN 1 ELSE 0 END AS TLChange,
		   RefreshedOn
	FROM AuditExceptions
	JOIN (
		SELECT SiteAudits.EDISID AS EDISID, MAX(TimeStamp) AS LastAudit
		FROM SiteAudits
		WHERE AuditType = 1
		GROUP BY SiteAudits.EDISID
	) AS LastManualAudits ON LastManualAudits.EDISID = AuditExceptions.EDISID
	JOIN AuditExceptionConfiguration ON 1=1
	LEFT JOIN SiteRankingCurrent ON SiteRankingCurrent.EDISID = AuditExceptions.EDISID
	WHERE ValidTo IS NULL
) AS ExceptionSites ON ExceptionSites.EDISID = SiteAuditors.EDISID
LEFT JOIN (
	SELECT EDISID
	FROM SiteAudits
	WHERE [TimeStamp] BETWEEN @From AND @To
	AND AuditType = 1
	GROUP BY EDISID
) AS SiteAudits ON SiteAudits.EDISID = SiteAuditors.EDISID
GROUP BY Configuration.PropertyValue, SiteAuditors.Auditor, SiteBDMs.BDMID, Users.UserName

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetAuditExceptionReport] TO PUBLIC
    AS [dbo];

