CREATE PROCEDURE [dbo].[GetCDAChecks]
(
	@From				DATETIME,
	@To					DATETIME,
	@IncludeWaterStill	BIT,
	@TeamLeaderName		VARCHAR(50)
)
AS

SET NOCOUNT ON

DECLARE @Issues TABLE(Issue VARCHAR(50), CDA VARCHAR(50), Customer VARCHAR(50), SiteID VARCHAR(25), SiteName VARCHAR(50), ReportLog VARCHAR(1000) NULL, TeamLeader INT, TeamLeaderName VARCHAR(50))
DECLARE @MasterDates TABLE([ID] INT NOT NULL, [Date] DATETIME NOT NULL)
DECLARE @MasterDates2 TABLE(EDISID INT NOT NULL, [Date] DATETIME NOT NULL)
DECLARE @EDISTimeSets TABLE(EDISID INT NOT NULL)
DECLARE @NVRAMClearedSites TABLE(EDISID INT NOT NULL)

DECLARE @ShadowRAMMonths AS INTEGER
SET @ShadowRAMMonths = 2

DECLARE @EndOfPreviousWeek DATETIME
SET @EndOfPreviousWeek = DATEADD(dd, -DATEPART(dw, GETDATE()), GETDATE())
SET @EndOfPreviousWeek = dbo.DateOnly(@EndOfPreviousWeek)

DECLARE @DefaultCDA VARCHAR(50)
DECLARE @DatabaseID INT
DECLARE @MultipleAuditors BIT

SELECT @DatabaseID = CAST(PropertyValue AS INTEGER)
FROM Configuration
WHERE PropertyName = 'Service Owner ID'

SELECT @MultipleAuditors = MultipleAuditors
FROM [EDISSQL1\SQL1].ServiceLogger.dbo.EDISDatabases
WHERE [ID] = @DatabaseID

SELECT @DefaultCDA = PropertyValue
FROM Configuration
WHERE PropertyName = 'AuditorName'

INSERT INTO @MasterDates
SELECT MasterDates.EDISID, MasterDates.[Date]
FROM FaultStack  WITH (NOLOCK)
JOIN MasterDates ON FaultStack.FaultID = MasterDates.ID
WHERE (FaultStack.[Description] LIKE 'Shadow RAM Copied%' OR FaultStack.[Description] LIKE 'Data copied to shadow RAM%')
--AND MasterDates.[Date] BETWEEN @From AND @To)

INSERT INTO @MasterDates2
SELECT MasterDates.EDISID, CONVERT(VARCHAR(19), DATEADD(ss, DATEPART(ss, FaultStack.[Time]), DATEADD(mi, DATEPART(mi, FaultStack.[Time]), DATEADD(hh, DATEPART(hh, FaultStack.[Time]), MasterDates.[Date]))), 20)
FROM FaultStack  WITH (NOLOCK)
JOIN MasterDates ON FaultStack.FaultID = MasterDates.ID
WHERE (FaultStack.[Description] LIKE 'Warning: Possibility of gap%'
AND MasterDates.[Date] BETWEEN DATEADD(month, -1, @From) AND @To)

DECLARE @WaterDispense TABLE (EDISID INT NOT NULL, Volume FLOAT NOT NULL)

INSERT INTO @WaterDispense
SELECT Sites.EDISID, SUM(Volume)
FROM WaterStack
JOIN MasterDates ON MasterDates.[ID] = WaterStack.WaterID
JOIN Sites ON Sites.EDISID = MasterDates.EDISID
AND MasterDates.[Date] BETWEEN DATEADD(week, -6, @From) AND @To
AND Sites.Hidden = 0
GROUP BY Sites.EDISID

INSERT INTO @EDISTimeSets
SELECT EDISID 
FROM SiteComments 
JOIN SiteCommentHeadingTypes ON SiteCommentHeadingTypes.[ID] = SiteComments.HeadingType
WHERE Type = 7
AND SiteCommentHeadingTypes.[Description] = 'Date/Time Set'
AND [Date] BETWEEN @From  AND @To

INSERT INTO @NVRAMClearedSites
SELECT EDISID
FROM SiteComments
JOIN SiteCommentHeadingTypes ON SiteCommentHeadingTypes.[ID] = SiteComments.HeadingType
WHERE Type = 7
AND SiteCommentHeadingTypes.[Description] = 'NVRAM Cleared'
AND [Date] BETWEEN @From  AND @To

--Missing Shadow RAM
INSERT INTO @Issues
(Issue, CDA, Customer, SiteID, SiteName, ReportLog)
SELECT 'Missing Shadow RAM', CASE WHEN Sites.SiteUser IS NULL OR LEN(Sites.SiteUser) = 0 OR @MultipleAuditors = 0 THEN @DefaultCDA ELSE Sites.SiteUser END, Configuration.PropertyValue, Sites.SiteID, Sites.[Name], NULL
FROM Sites
JOIN Configuration ON Configuration.PropertyName = 'Company Name'
WHERE EDISID NOT IN(
SELECT [ID]
FROM(
	SELECT	[ID]
	FROM 	@MasterDates As MDates
	JOIN 	Sites ON MDates.[ID] = Sites.EDISID
	AND 	([Date] BETWEEN DateAdd(d, 1 - DAY(LastDownload), DateAdd(m, -(@ShadowRAMMonths-1), LastDownload)) AND LastDownload)
	GROUP BY MDates.[ID], MONTH([Date])
) As CountOfShadow
GROUP BY [ID]
HAVING COUNT([ID]) >= @ShadowRAMMonths) 
AND (Sites.SystemTypeID = 1 OR Sites.SystemTypeID = 5) --EDIS2 or EDIS3
AND Hidden = 0
AND LastDownload > DATEADD(m, -2 , GETDATE())
ORDER BY SiteID

--Missing Data
INSERT INTO @Issues
(Issue, CDA, Customer, SiteID, SiteName, ReportLog)
SELECT 'Potential Missing Data', CASE WHEN Sites.SiteUser IS NULL OR LEN(Sites.SiteUser) = 0 OR @MultipleAuditors = 0 THEN @DefaultCDA ELSE Sites.SiteUser END, Configuration.PropertyValue, Sites.SiteID, Sites.[Name], CAST(MasterDates.[Date] AS VARCHAR)
FROM Sites
JOIN Configuration ON Configuration.PropertyName = 'Company Name'
JOIN @MasterDates2 AS MasterDates ON MasterDates.EDISID = Sites.EDISID
WHERE (Sites.SystemTypeID = 2)
AND Hidden = 0
ORDER BY SiteID

--Font Setups to Action
INSERT INTO @Issues
(Issue, CDA, Customer, SiteID, SiteName, ReportLog)
SELECT 'Font Setup To Action', CASE WHEN Sites.SiteUser IS NULL OR LEN(Sites.SiteUser) = 0 OR @MultipleAuditors = 0 THEN @DefaultCDA ELSE Sites.SiteUser END, Configuration.PropertyValue, Sites.SiteID, Sites.[Name], NULL
FROM Sites
JOIN ProposedFontSetups ON ProposedFontSetups.EDISID = Sites.EDISID
JOIN Configuration ON Configuration.PropertyName = 'Company Name'
WHERE ProposedFontSetups.Completed = 0
AND ProposedFontSetups.Available = 1
AND Sites.Hidden = 0
ORDER BY SiteID

--New Installs
INSERT INTO @Issues
(Issue, CDA, Customer, SiteID, SiteName, ReportLog)
SELECT 'New Install', CASE WHEN Sites.SiteUser IS NULL OR LEN(Sites.SiteUser) = 0 OR @MultipleAuditors = 0 THEN @DefaultCDA ELSE Sites.SiteUser END, Configuration.PropertyValue, Sites.SiteID, Sites.[Name], NULL
FROM Sites
JOIN ProposedFontSetups ON ProposedFontSetups.EDISID = Sites.EDISID
LEFT JOIN Calls ON Calls.[ID] = ProposedFontSetups.CallID
LEFT JOIN CallStatusHistory ON CallStatusHistory.CallID = Calls.[ID]
LEFT JOIN SupplementaryCallStatusItems ON SupplementaryCallStatusItems.CallID = Calls.[ID]
JOIN Configuration ON Configuration.PropertyName = 'Company Name'
WHERE ProposedFontSetups.Available = 1
AND ProposedFontSetups.Completed = 0
AND Sites.Hidden = 1
AND (CallStatusHistory.[ID] IN (4, 5) OR Calls.[ID] IS NULL)
--AND (CallStatusHistory.[ID] =	(SELECT MAX(CallStatusHistory.[ID])
				--FROM CallStatusHistory
				--WHERE CallID = Calls.[ID])
AND (SupplementaryCallStatusItems.[ID] =	(SELECT MAX(SupplementaryCallStatusItems.[ID])
						FROM SupplementaryCallStatusItems
						WHERE CallID = Calls.[ID])
	OR SupplementaryCallStatusItems.[ID] IS NULL)
AND Calls.AbortReasonID = 0
AND Calls.CallTypeID = 2


--CRC Issues
INSERT INTO @Issues
(Issue, CDA, Customer, SiteID, SiteName, ReportLog)
SELECT 'CRC Issue', CASE WHEN Sites.SiteUser IS NULL OR LEN(Sites.SiteUser) = 0 OR @MultipleAuditors = 0 THEN @DefaultCDA ELSE Sites.SiteUser END, Configuration.PropertyValue, Sites.SiteID, Sites.[Name], DownloadReports.ReportText
FROM Sites
JOIN DownloadReports ON DownloadReports.EDISID = Sites.EDISID
FULL JOIN DownloadReports AS SuccessReports ON SuccessReports.EDISID = Sites.EDISID AND SuccessReports.DownloadedOn BETWEEN @From AND @To AND SuccessReports.ReportText LIKE '%success%'
JOIN Configuration ON Configuration.PropertyName = 'Company Name'
WHERE Hidden = 0
AND DownloadReports.DownloadedOn BETWEEN @From AND @To
AND DownloadReports.ReportText LIKE '%CRC%'
AND (SuccessReports.DownloadedOn IS NULL OR SuccessReports.DownloadedOn < DownloadReports.DownloadedOn)
GROUP BY Sites.SiteUser, Configuration.PropertyValue, Sites.SiteID, Sites.[Name], DownloadReports.ReportText

--NVRAM Corrupt
INSERT INTO @Issues
(Issue, CDA, Customer, SiteID, SiteName, ReportLog)
SELECT 'NVRAM Corrupt', CASE WHEN Sites.SiteUser IS NULL OR LEN(Sites.SiteUser) = 0 OR @MultipleAuditors = 0 THEN @DefaultCDA ELSE Sites.SiteUser END, Configuration.PropertyValue, Sites.SiteID, Sites.[Name], DownloadReports.ReportText
FROM Sites
JOIN DownloadReports ON DownloadReports.EDISID = Sites.EDISID
FULL JOIN DownloadReports AS SuccessReports ON SuccessReports.EDISID = Sites.EDISID AND SuccessReports.DownloadedOn BETWEEN @From AND @To AND SuccessReports.ReportText LIKE '%success%'
JOIN Configuration ON Configuration.PropertyName = 'Company Name'
WHERE Hidden = 0
AND DownloadReports.DownloadedOn BETWEEN @From AND @To
AND DownloadReports.ReportText LIKE '%NVRAM corrupt%'
AND (SuccessReports.DownloadedOn IS NULL OR SuccessReports.DownloadedOn < DownloadReports.DownloadedOn)
GROUP BY Sites.SiteUser, Configuration.PropertyValue, Sites.SiteID, Sites.[Name], DownloadReports.ReportText

--EDIS time-outs
INSERT INTO @Issues
(Issue, CDA, Customer, SiteID, SiteName, ReportLog)
SELECT 'EDIS time-out', CASE WHEN Sites.SiteUser IS NULL OR LEN(Sites.SiteUser) = 0 OR @MultipleAuditors = 0 THEN @DefaultCDA ELSE Sites.SiteUser END, Configuration.PropertyValue, Sites.SiteID, Sites.[Name], DownloadReports.ReportText
FROM Sites
JOIN DownloadReports ON DownloadReports.EDISID = Sites.EDISID
JOIN Configuration ON Configuration.PropertyName = 'Company Name'
WHERE Hidden = 0
AND DownloadedOn BETWEEN @From AND @To
AND ReportText LIKE '%time is out%'
AND Sites.EDISID NOT IN (SELECT EDISID FROM @EDISTimeSets)
GROUP BY Sites.SiteUser, Configuration.PropertyValue, Sites.SiteID, Sites.[Name], DownloadReports.ReportText

--Future data
INSERT INTO @Issues
(Issue, CDA, Customer, SiteID, SiteName, ReportLog)
SELECT 'Future Data', CASE WHEN Sites.SiteUser IS NULL OR LEN(Sites.SiteUser) = 0 OR @MultipleAuditors = 0 THEN @DefaultCDA ELSE Sites.SiteUser END, Configuration.PropertyValue, Sites.SiteID, Sites.[Name], DownloadReports.ReportText
FROM Sites
JOIN DownloadReports ON DownloadReports.EDISID = Sites.EDISID
JOIN Configuration ON Configuration.PropertyName = 'Company Name'
WHERE Hidden = 0
AND DownloadReports.DownloadedOn BETWEEN @From AND @To
AND DownloadReports.ReportText LIKE '%Warning: Potential double-dispense%'
AND Sites.EDISID NOT IN (SELECT EDISID FROM @NVRAMClearedSites)
GROUP BY Sites.SiteUser, Configuration.PropertyValue, Sites.SiteID, Sites.[Name], DownloadReports.ReportText

--Water still in data
IF @IncludeWaterStill = 1
BEGIN
	INSERT INTO @Issues
	(Issue, CDA, Customer, SiteID, SiteName, ReportLog)
	SELECT 'Water Still in Data',
		CASE WHEN Sites.SiteUser IS NULL OR LEN(Sites.SiteUser) = 0 OR @MultipleAuditors = 0 THEN @DefaultCDA ELSE Sites.SiteUser END,
		Configuration.PropertyValue,
		Sites.SiteID,
		Sites.[Name],
		NULL
	FROM DLData
	JOIN Products ON Products.[ID] = DLData.Product
	JOIN MasterDates ON MasterDates.[ID] = DLData.DownloadID
	JOIN Sites ON Sites.EDISID = MasterDates.EDISID
	JOIN Configuration ON Configuration.PropertyName = 'Company Name'
	WHERE Products.IsWater = 1
	AND Sites.Hidden = 0
	AND MasterDates.[Date] BETWEEN DATEADD(week, -2, @From) AND @EndOfPreviousWeek
	GROUP BY Sites.SiteUser, Configuration.PropertyValue, Sites.SiteID, Sites.[Name]
END

--No Dispense on Water Line
INSERT INTO @Issues
(Issue, CDA, Customer, SiteID, SiteName, ReportLog)
SELECT 'No Dispense on Water Line', CASE WHEN Sites.SiteUser IS NULL OR LEN(Sites.SiteUser) = 0 OR @MultipleAuditors = 0 THEN @DefaultCDA ELSE Sites.SiteUser END, Configuration.PropertyValue, Sites.SiteID, Sites.[Name], NULL
FROM Sites
JOIN Configuration ON Configuration.PropertyName = 'Company Name'
WHERE Sites.Hidden = 0
AND Sites.SiteClosed = 0
AND Sites.LastDownload >= DATEADD(week, -1, @From)
AND EDISID NOT IN
(
	SELECT EDISID
	FROM @WaterDispense
)
AND SiteID NOT IN
(
	SELECT SiteID
	FROM @Issues
	WHERE Issue = 'Water Still in Data'
)
GROUP BY Sites.SiteUser, Configuration.PropertyValue, Sites.SiteID, Sites.[Name]

SELECT Issue,
       CDA,
       Customer,
       SiteID,
       SiteName,
       ReportLog,
       Auditors.TeamLeader AS TeamLeaderID,
       dbo.udfNiceName(TeamLeaderName.[Login]) AS TeamLeaderName
FROM @Issues
JOIN [SQL1\SQL1].ServiceLogger.dbo.Logins AS Auditors ON LOWER(dbo.udfNiceName(Auditors.[Login])) = LOWER(dbo.udfNiceName(CDA))
JOIN [SQL1\SQL1].ServiceLogger.dbo.Logins AS TeamLeaderName ON TeamLeaderName.ID = Auditors.TeamLeader
WHERE dbo.udfNiceName(TeamLeaderName.[Login]) = @TeamLeaderName

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetCDAChecks] TO PUBLIC
    AS [dbo];

