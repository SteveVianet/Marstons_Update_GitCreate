CREATE PROCEDURE [dbo].[GetAuditExceptionReportDetail]
(
	@From		DATETIME,
	@To			DATETIME
)
AS

SELECT  C.PropertyValue AS Customer,
		Sites.SiteID,
		Sites.Name,
		Sites.PostCode,
		CTL.Name AS CurrentLight,
		NTL.Name AS NewLight,
		CAST(CASE WHEN TrafficLightColour <> CurrentTrafficLightColour THEN 1 ELSE 0 END AS BIT) AS TrafficLightChange,
		A.TrafficLightFailReason,
		A.Tampering,
		A.NoWater,
		A.NotDownloading,
		A.EDISTimeOut,
		A.MissingShadowRAM,
		A.MissingData,
		A.FontSetupsToAction,
		A.CallOnHold,
		A.NotAuditedInThreeWeeks,
		A.StoppedLines,
		A.CalibrationIssue,
		A.NewProductKeg,
		A.NewProductCask,
		A.ClosedWithDelivery,
		A.StoppedLineReasons,
		A.CalibrationIssueReasons,
		A.NewProductKegReasons,
		A.NewProductCaskReasons,
		A.ClosedOrMissingShadowRAM,
		A.[From], A.[To], A.RefreshedOn, dbo.udfNiceName(A.RefreshedBy) AS RefreshedBy
FROM AuditExceptions AS A
JOIN Configuration AS C ON C.PropertyName = 'Company Name'
JOIN Sites ON Sites.EDISID = A.EDISID
JOIN SiteRankingTypes AS CTL ON CTL.ID = A.CurrentTrafficLightColour
JOIN SiteRankingTypes AS NTL ON NTL.ID = A.TrafficLightColour
WHERE A.RefreshedOn BETWEEN @From AND @To
ORDER BY C.PropertyValue, Sites.SiteID, RefreshedOn

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetAuditExceptionReportDetail] TO PUBLIC
    AS [dbo];

