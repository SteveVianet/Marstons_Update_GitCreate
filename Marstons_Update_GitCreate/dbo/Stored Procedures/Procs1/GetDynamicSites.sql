CREATE PROCEDURE [dbo].[GetDynamicSites]
(
	@Field			VARCHAR(255),
	@Value			VARCHAR(255)
)

AS

SET NOCOUNT ON

IF @Field = 'SystemType'
	SELECT EDISID
	FROM dbo.Sites
	JOIN dbo.SystemTypes ON SystemTypes.[ID] = Sites.SystemTypeID
	WHERE SystemTypes.[Description] = @Value
	ORDER BY Sites.SiteID

ELSE IF @Field = 'Region'
	SELECT EDISID
	FROM dbo.Sites
	JOIN dbo.Regions ON Regions.[ID] = Sites.Region
	WHERE Regions.[Description] = @Value
	ORDER BY Sites.SiteID

ELSE IF @Field = 'Area'
	SELECT EDISID
	FROM dbo.Sites
	JOIN dbo.Areas ON Areas.[ID] = Sites.AreaID
	WHERE Areas.[Description] = @Value
	ORDER BY Sites.SiteID

ELSE IF @Field = 'SiteClosed'
BEGIN
	IF @Value = 'True' OR @Value = '1'
		SELECT EDISID
		FROM dbo.Sites
		WHERE SiteClosed = 1
		ORDER BY Sites.SiteID
	ELSE
		SELECT EDISID
		FROM dbo.Sites
		WHERE SiteClosed = 0
		ORDER BY Sites.SiteID
END

ELSE IF @Field = 'InVRS'
BEGIN
	IF @Value = 'True' OR @Value = '1'
		SELECT EDISID
		FROM dbo.Sites
		WHERE IsVRSMember = 1
		ORDER BY Sites.SiteID

	ELSE
		SELECT EDISID
		FROM dbo.Sites
		WHERE IsVRSMember = 0
		ORDER BY Sites.SiteID

END

ELSE IF @Field = 'HasProperty'
	SELECT SiteProperties.EDISID
	FROM dbo.SiteProperties
	JOIN dbo.Properties ON Properties.[ID] = SiteProperties.PropertyID
	JOIN dbo.Sites ON Sites.EDISID = SiteProperties.EDISID
	WHERE Properties.[Name] = @Value
	ORDER BY Sites.SiteID

ELSE IF @Field = 'PropertyValue'
BEGIN
	DECLARE @PropertyName	VARCHAR(255)
	DECLARE @PropertyValue	VARCHAR(255)
	
	SET @PropertyName = LEFT(@Value, CHARINDEX('=', @Value) - 1)
	SET @PropertyValue = SUBSTRING(@Value, CHARINDEX('=', @Value) + 1, 1000)
		
	SELECT SiteProperties.EDISID
	FROM dbo.SiteProperties
	JOIN dbo.Properties ON Properties.[ID] = SiteProperties.PropertyID
	JOIN dbo.Sites ON Sites.EDISID = SiteProperties.EDISID
	WHERE Properties.[Name] = @PropertyName
	AND SiteProperties.Value = @PropertyValue
	ORDER BY Sites.SiteID

END

ELSE IF @Field = 'User'
BEGIN
	DECLARE @AllSitesVisible	INT
	
	SELECT @AllSitesVisible = AllSitesVisible
	FROM dbo.UserTypes
	JOIN dbo.Users ON Users.UserType = UserTypes.[ID]
	WHERE Users.UserName = @Value
	
	IF @AllSitesVisible IS NULL
		RETURN 0

	ELSE IF @AllSitesVisible = 1
		SELECT EDISID
		FROM dbo.Sites
		ORDER BY Sites.SiteID

	ELSE
		SELECT Sites.EDISID
		FROM dbo.UserSites
		JOIN dbo.Users ON Users.[ID] = UserSites.UserID
		JOIN dbo.Sites ON Sites.EDISID = UserSites.EDISID
		WHERE Users.UserName = @Value
		ORDER BY Sites.SiteID

END

ELSE IF @Field = 'NotDownloadedFor'
	SELECT EDISID
	FROM dbo.Sites
	WHERE DATEDIFF(dd, LastDownload, CAST(CAST(GETDATE() AS VARCHAR(12)) AS DATETIME)) > CAST(@Value AS INTEGER)
	OR LastDownload IS NULL
	ORDER BY LastDownload

ELSE IF @Field = 'Downloaded'
BEGIN
	IF @Value = 'Nucleus'
		SELECT SiteProperties.EDISID
		FROM dbo.SiteProperties
		JOIN dbo.Properties ON Properties.[ID] = SiteProperties.PropertyID
		JOIN dbo.Sites ON Sites.EDISID = SiteProperties.EDISID
		WHERE Properties.Name = 'AutoFaultAssign'
		AND SiteProperties.Value = '22'
		ORDER BY Sites.SiteID
	ELSE
		SELECT EDISID
		FROM Sites
		WHERE EDISID NOT IN (
			SELECT SiteProperties.EDISID
			FROM dbo.SiteProperties
			JOIN dbo.Properties ON Properties.[ID] = SiteProperties.PropertyID
			WHERE Properties.Name = 'AutoFaultAssign'
			AND SiteProperties.Value = '22')
		ORDER BY SiteID
		
END
	
ELSE IF @Field = 'Audited'
BEGIN
	IF @Value = 'Nucleus'
		SELECT SiteProperties.EDISID
		FROM dbo.SiteProperties
		JOIN dbo.Properties ON Properties.[ID] = SiteProperties.PropertyID
		JOIN dbo.Sites ON Sites.EDISID = SiteProperties.EDISID
		WHERE Properties.Name = 'AutoFaultAssign'
		AND SiteProperties.Value = '54'
		ORDER BY Sites.SiteID
	ELSE
		SELECT EDISID
		FROM Sites
		WHERE EDISID NOT IN (
			SELECT SiteProperties.EDISID
			FROM dbo.SiteProperties
			JOIN dbo.Properties ON Properties.[ID] = SiteProperties.PropertyID
			WHERE Properties.Name = 'AutoFaultAssign'
			AND SiteProperties.Value = '54')
		ORDER BY SiteID

END

--Double Dispense
ELSE IF @Field = 'MissingShadowRAM'
BEGIN
	DECLARE @Months AS INTEGER
	SET @Months = CAST(@Value AS INTEGER)

	DECLARE @MasterDates TABLE([ID] INT NOT NULL, MDate DATETIME NOT NULL)
	INSERT INTO @MasterDates
	SELECT MasterDates.EDISID, MasterDates.Date
	FROM FaultStack  WITH (NOLOCK)
	JOIN MasterDates ON FaultStack.FaultID = MasterDates.ID
	WHERE (FaultStack.[Description] LIKE 'Shadow RAM Copied%' OR FaultStack.[Description] LIKE 'Data copied to shadow RAM%')
	
	SELECT EDISID FROM Sites
	WHERE EDISID NOT IN(
	SELECT [ID]
	FROM(
		SELECT	[ID]
		FROM 	@MasterDates As MDates
		JOIN 	Sites ON MDates.[ID] = Sites.EDISID
		AND 	(MDate BETWEEN DateAdd(d, 1 - DAY(LastDownload), DateAdd(m, -(@Months-1), LastDownload)) AND LastDownload)
		GROUP BY MDates.[ID], MONTH(MDate)
	) As CountOfShadow
	GROUP BY [ID]
	HAVING COUNT([ID]) >= @Months) 
	AND (Sites.SystemTypeID = 1 OR Sites.SystemTypeID = 5) --EDIS2 or EDIS3
	AND Hidden = 0
	AND LastDownload > DATEADD(m, -2 , GETDATE())
	ORDER BY SiteID
END
	
--Missing Data
ELSE IF @Field = 'PotentialMissingData'
BEGIN
	DECLARE @Weeks AS INTEGER
	DECLARE @WeeksBehind AS INTEGER
	DECLARE @ToDate DATETIME
	DECLARE @EndOfPreviousWeek DATETIME

	SET DATEFIRST 1
	SET @Weeks = CAST(@Value AS INTEGER)
	SET @WeeksBehind = ISNULL((SELECT CAST(PropertyValue AS INT) FROM Configuration WHERE PropertyName = 'AuditWeeksBehind'), 1)-1
	SET @EndOfPreviousWeek = DATEADD(dd, -DATEPART(dw, GETDATE()), GETDATE())
	SET @EndOfPreviousWeek = dbo.DateOnly(@EndOfPreviousWeek)
	SET @ToDate = DATEADD(ww, -@WeeksBehind, @EndOfPreviousWeek)

	DECLARE @MasterDates2 TABLE([ID] INT NOT NULL, MDate DATETIME NOT NULL)
	INSERT INTO @MasterDates2
	SELECT MasterDates.EDISID, MasterDates.Date
	FROM FaultStack  WITH (NOLOCK)
	JOIN MasterDates ON FaultStack.FaultID = MasterDates.ID
	WHERE (FaultStack.[Description] LIKE 'Warning: Possibility of gap%')
	
	SELECT EDISID FROM Sites
	WHERE EDISID IN(
		SELECT	[ID]
		FROM 	@MasterDates2 As MDates
		JOIN 	Sites ON MDates.[ID] = Sites.EDISID
		AND 	(MDate BETWEEN DateAdd(d, -(@Weeks*7), @ToDate) AND @ToDate))
	AND (Sites.SystemTypeID = 2) --EDISBOX
	AND Hidden = 0
	ORDER BY SiteID
END

ELSE IF @Field = 'TamperingAssigned'
BEGIN
	SELECT TamperCases.EDISID
	FROM TamperCaseEvents
	JOIN TamperCases ON TamperCases.CaseID = TamperCaseEvents.CaseID
	JOIN (
		SELECT EDISID, MAX(EventDate) AS MaxCaseDate
		FROM TamperCases
		JOIN TamperCaseEvents ON TamperCaseEvents.CaseID = TamperCases.CaseID
		GROUP BY EDISID
	) AS CurrentCases ON (CurrentCases.EDISID = TamperCases.EDISID
										AND CurrentCases.MaxCaseDate = TamperCaseEvents.EventDate)
	JOIN InternalUsers ON InternalUsers.ID = TamperCaseEvents.UserID
	WHERE StateID IN (1,2,4,5)
	AND UPPER(REPLACE(REPLACE(UserName,'.',' '),'MAINGROUP\','')) = UPPER(@Value)
	GROUP BY TamperCases.EDISID
END

ELSE IF @Field = 'SiteAuditor'
BEGIN
    SELECT Sites.EDISID
    FROM Sites
    WHERE UPPER(REPLACE(REPLACE(SiteUser,'.',' '),'MAINGROUP\','')) = UPPER(@Value)
END
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetDynamicSites] TO PUBLIC
    AS [dbo];

