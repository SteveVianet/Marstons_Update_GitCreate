
CREATE PROCEDURE [dbo].[GetAuditExceptions]
(
	@UserID		INT = NULL,
	@ScheduleID	INT = NULL,
	@EDISID		INT = NULL
)
AS

--SELECT * FROM AuditExceptions WHERE ValidTo IS NULL

--DECLARE	@UserID		INT = NULL
--DECLARE	@ScheduleID	INT = 236 --NULL
--DECLARE	@EDISID		INT = NULL

SET NOCOUNT ON

IF @UserID IS NOT NULL AND @ScheduleID IS NULL
BEGIN
	SELECT	AuditExceptions.EDISID,
			AuditExceptions.Tampering,
			AuditExceptions.NoWater,
			AuditExceptions.NotDownloading,
			AuditExceptions.EDISTimeOut,
			AuditExceptions.MissingShadowRAM,
			AuditExceptions.MissingData,
			AuditExceptions.FontSetupsToAction,
			AuditExceptions.CallOnHold,
			AuditExceptions.NotAuditedInThreeWeeks,
			AuditExceptions.StoppedLines,
			AuditExceptions.CalibrationIssue,
			AuditExceptions.NewProductKeg,
			AuditExceptions.NewProductCask,
			AuditExceptions.ClosedWithDelivery,
			AuditExceptions.TrafficLightColour,
			ISNULL(AuditExceptions.TrafficLightFailReason,'') AS TrafficLightFailReason,
			--BDMUsers.UserName,
			ISNULL(SiteAudits.LastAuditDate, 0) AS LastAuditDate,
			ISNULL(SiteAudits.LastIDraughtAuditDate, 0) AS LastIDraughtAuditDate,
			ISNULL(SiteAudits.LastReviewDate, 0) AS LastReviewDate,
			ISNULL(AuditExceptions.CurrentTrafficLightColour, 5) AS CurrentTrafficLightColour,
			REPLACE(ISNULL(AuditExceptions.StoppedLineReasons, ''), '&amp;', '&') AS StoppedLineReasons,
			REPLACE(ISNULL(AuditExceptions.CalibrationIssueReasons, ''), '&amp;', '&') AS CalibrationIssueReasons,
			REPLACE(ISNULL(AuditExceptions.NewProductKegReasons, ''), '&amp;', '&') AS NewProductKegReasons,
			REPLACE(ISNULL(AuditExceptions.NewProductCaskReasons, ''), '&amp;', '&') AS NewProductCaskReasons,
			ISNULL(AuditExceptions.RefreshedOn, CONVERT(DATETIME, '1990-1-1')) AS RefreshedOn,
			AuditExceptions.ClosedOrMissingShadowRAM,
			ISNULL(AuditExceptions.[From], CONVERT(DATETIME, '1990-1-1')) AS [From],
			ISNULL(AuditExceptions.[To], CONVERT(DATETIME, '1990-1-1')) AS [To]
	FROM AuditExceptions
	JOIN (	SELECT EDISID
			FROM UserSites
			JOIN Users ON Users.[ID] = UserSites.UserID AND UserSites.UserID = @UserID
		 ) AS UserSites ON UserSites.EDISID = AuditExceptions.EDISID
	LEFT JOIN (	SELECT EDISID, 
					   MAX(CASE WHEN AuditType = 1 THEN [TimeStamp] ELSE 0 END) AS LastAuditDate,
					   MAX(CASE WHEN AuditType = 10 THEN [TimeStamp] ELSE 0 END) AS LastIDraughtAuditDate,
					   MAX(CASE WHEN AuditType = 99 THEN [TimeStamp] ELSE 0 END) AS LastReviewDate
				FROM SiteAudits
				GROUP BY EDISID
			  ) AS SiteAudits ON SiteAudits.EDISID = AuditExceptions.EDISID AND AuditExceptions.ValidTo IS NULL
	WHERE ValidTo IS NULL
	
END

IF @ScheduleID IS NOT NULL AND @UserID IS NULL
BEGIN
	CREATE TABLE #ScheduleSites(EDISID INT)
	DECLARE @Description VARCHAR(255)
	DECLARE @Field VARCHAR(255)
	DECLARE @Value VARCHAR(255)
	
	SELECT @Description = [Description]
	FROM Schedules
	WHERE [ID] = @ScheduleID

	IF LEFT(@Description, 1) = '$'
	BEGIN
		SET @Value = SUBSTRING(@Description, CHARINDEX('=', @Description, 2)+1, CHARINDEX(':', @Description, 2))
		SET @Value = LEFT(@Value, CHARINDEX(':', @Value)-1)
		
		SET @Field = SUBSTRING(@Description, 2, CHARINDEX('=', @Description, 1)-2)
		
		INSERT INTO #ScheduleSites
		EXEC dbo.GetDynamicSites @Field, @Value
		
	END
	ELSE
	BEGIN
		INSERT INTO #ScheduleSites
		SELECT EDISID
		FROM ScheduleSites
		WHERE ScheduleID = @ScheduleID
		
	END
	
	SELECT	AuditExceptions.EDISID,
			AuditExceptions.Tampering,
			AuditExceptions.NoWater,
			AuditExceptions.NotDownloading,
			AuditExceptions.EDISTimeOut,
			AuditExceptions.MissingShadowRAM,
			AuditExceptions.MissingData,
			AuditExceptions.FontSetupsToAction,
			AuditExceptions.CallOnHold,
			AuditExceptions.NotAuditedInThreeWeeks,
			AuditExceptions.StoppedLines,
			AuditExceptions.CalibrationIssue,
			AuditExceptions.NewProductKeg,
			AuditExceptions.NewProductCask,
			AuditExceptions.ClosedWithDelivery,
			AuditExceptions.TrafficLightColour,
			ISNULL(AuditExceptions.TrafficLightFailReason,'') AS TrafficLightFailReason,
			ISNULL(SiteAudits.LastAuditDate, 0) AS LastAuditDate,
			ISNULL(SiteAudits.LastIDraughtAuditDate, 0) AS LastIDraughtAuditDate,
			ISNULL(SiteAudits.LastReviewDate, 0) AS LastReviewDate,
			ISNULL(AuditExceptions.CurrentTrafficLightColour, 5) AS CurrentTrafficLightColour,
			REPLACE(ISNULL(AuditExceptions.StoppedLineReasons, ''), '&amp;', '&') AS StoppedLineReasons,
			REPLACE(ISNULL(AuditExceptions.CalibrationIssueReasons, ''), '&amp;', '&') AS CalibrationIssueReasons,
			REPLACE(ISNULL(AuditExceptions.NewProductKegReasons, ''), '&amp;', '&') AS NewProductKegReasons,
			REPLACE(ISNULL(AuditExceptions.NewProductCaskReasons, ''), '&amp;', '&') AS NewProductCaskReasons,
			ISNULL(AuditExceptions.RefreshedOn, CONVERT(DATETIME, '1990-1-1')) AS RefreshedOn,
			AuditExceptions.ClosedOrMissingShadowRAM,
			ISNULL(AuditExceptions.[From], CONVERT(DATETIME, '1990-1-1')) AS [From],
			ISNULL(AuditExceptions.[To], CONVERT(DATETIME, '1990-1-1')) AS [To]
	FROM AuditExceptions
	JOIN (	SELECT EDISID
			FROM #ScheduleSites AS ScheduleSites
		 ) AS ScheduleSites ON ScheduleSites.EDISID = AuditExceptions.EDISID
	LEFT JOIN (	SELECT EDISID, 
					   MAX(CASE WHEN AuditType = 1 THEN [TimeStamp] ELSE 0 END) AS LastAuditDate,
					   MAX(CASE WHEN AuditType = 10 THEN [TimeStamp] ELSE 0 END) AS LastIDraughtAuditDate,
					   MAX(CASE WHEN AuditType = 99 THEN [TimeStamp] ELSE 0 END) AS LastReviewDate
				FROM SiteAudits
				GROUP BY EDISID
			  ) AS SiteAudits ON SiteAudits.EDISID = AuditExceptions.EDISID AND AuditExceptions.ValidTo IS NULL
	WHERE ValidTo IS NULL
	ORDER BY EDISID
	
	DROP TABLE #ScheduleSites
END

IF @UserID IS NULL AND @ScheduleID IS NULL
BEGIN
	SELECT	AuditExceptions.EDISID,
			AuditExceptions.Tampering,
			AuditExceptions.NoWater,
			AuditExceptions.NotDownloading,
			AuditExceptions.EDISTimeOut,
			AuditExceptions.MissingShadowRAM,
			AuditExceptions.MissingData,
			AuditExceptions.FontSetupsToAction,
			AuditExceptions.CallOnHold,
			AuditExceptions.NotAuditedInThreeWeeks,
			AuditExceptions.StoppedLines,
			AuditExceptions.CalibrationIssue,
			AuditExceptions.NewProductKeg,
			AuditExceptions.NewProductCask,
			AuditExceptions.ClosedWithDelivery,
			AuditExceptions.TrafficLightColour,
			ISNULL(AuditExceptions.TrafficLightFailReason,'') AS TrafficLightFailReason,
			--BDMUsers.UserName,
			ISNULL(SiteAudits.LastAuditDate, 0) AS LastAuditDate,
			ISNULL(SiteAudits.LastIDraughtAuditDate, 0) AS LastIDraughtAuditDate,
			ISNULL(SiteAudits.LastReviewDate, 0) AS LastReviewDate,
			ISNULL(AuditExceptions.CurrentTrafficLightColour, 5) AS CurrentTrafficLightColour,
			REPLACE(ISNULL(AuditExceptions.StoppedLineReasons, ''), '&amp;', '&') AS StoppedLineReasons,
			REPLACE(ISNULL(AuditExceptions.CalibrationIssueReasons, ''), '&amp;', '&') AS CalibrationIssueReasons,
			REPLACE(ISNULL(AuditExceptions.NewProductKegReasons, ''), '&amp;', '&') AS NewProductKegReasons,
			REPLACE(ISNULL(AuditExceptions.NewProductCaskReasons, ''), '&amp;', '&') AS NewProductCaskReasons,
			ISNULL(AuditExceptions.RefreshedOn, CONVERT(DATETIME, '1990-1-1')) AS RefreshedOn,
			AuditExceptions.ClosedOrMissingShadowRAM,
			ISNULL(AuditExceptions.[From], CONVERT(DATETIME, '1990-1-1')) AS [From],
			ISNULL(AuditExceptions.[To], CONVERT(DATETIME, '1990-1-1')) AS [To]
	FROM AuditExceptions
	LEFT JOIN (	SELECT EDISID, 
					   MAX(CASE WHEN AuditType = 1 THEN [TimeStamp] ELSE 0 END) AS LastAuditDate,
					   MAX(CASE WHEN AuditType = 10 THEN [TimeStamp] ELSE 0 END) AS LastIDraughtAuditDate,
					   MAX(CASE WHEN AuditType = 99 THEN [TimeStamp] ELSE 0 END) AS LastReviewDate
				FROM SiteAudits
				GROUP BY EDISID
			  ) AS SiteAudits ON SiteAudits.EDISID = AuditExceptions.EDISID AND AuditExceptions.ValidTo IS NULL
	WHERE ValidTo IS NULL
	AND (AuditExceptions.EDISID = @EDISID OR @EDISID IS NULL)
END


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetAuditExceptions] TO PUBLIC
    AS [dbo];

