CREATE PROCEDURE [dbo].[GetWebUserCDSubUserOverview]
(
	@UserID				INT,
	@ShowOnlyLiveSites	BIT = 1,
	@RegionID			INT = NULL
)
AS

SET NOCOUNT ON

DECLARE @CurrentPeriod VARCHAR(50)
DECLARE @CurrentYear VARCHAR(5)
DECLARE @CurrentPeriodWeeks INT
DECLARE @CDCashValue FLOAT
DECLARE @HighCDValue FLOAT
DECLARE @ExcludeFromRedsPropertyID INT
DECLARE @UserHasAllSites BIT
DECLARE @UserTypeID INT
DECLARE @PeriodCount INT
DECLARE @LastThreePeriods VARCHAR(100)
DECLARE @LastTwelvePeriods VARCHAR(100)
DECLARE @SQL VARCHAR(8000)

CREATE TABLE #RedsThisYear(UserID INT, UserType INT, UserName VARCHAR(100), DatabaseID INT, EDISID INT, Period VARCHAR(10), CD FLOAT, PeriodDispensed FLOAT, PeriodYear VARCHAR(10), PeriodWeeks INT, PeriodNumber VARCHAR(10), Area VARCHAR(100))
CREATE TABLE #LastThreePeriods(PeriodNumber INT, Period VARCHAR(10))
CREATE TABLE #LastTwelvePeriods(PeriodNumber INT, Period VARCHAR(10))

CREATE TABLE #UserPeerSites(EDISID INT)

SELECT @UserTypeID = UserType, @UserHasAllSites = AllSitesVisible
FROM dbo.Users
JOIN UserTypes ON UserTypes.[ID] = Users.UserType
WHERE Users.[ID] = @UserID

SELECT @CDCashValue = CAST(PropertyValue AS FLOAT)
FROM dbo.Configuration
WHERE PropertyName = 'Calculated Deficit Cash Value'

SELECT @HighCDValue = CAST(PropertyValue AS FLOAT)
FROM dbo.Configuration
WHERE PropertyName = 'Calculated Deficit High CD Threshold'

SELECT @ExcludeFromRedsPropertyID = [ID]
FROM dbo.Properties
WHERE Name = 'Exclude From Reds'

IF @UserTypeID = 1
BEGIN
	INSERT INTO #UserPeerSites
	SELECT Sites.EDISID
	FROM UserSites
	JOIN Users ON Users.ID = UserSites.UserID
	JOIN Sites ON Sites.EDISID = UserSites.EDISID
	WHERE Sites.Hidden = 0
	AND Users.[ID] = @UserID
	
END
ELSE IF @UserTypeID = 2
BEGIN
	INSERT INTO #UserPeerSites
	SELECT UserSites.EDISID
	FROM UserSites
	JOIN Users ON Users.ID = UserSites.UserID
	JOIN Sites ON Sites.EDISID = UserSites.EDISID
	WHERE UserSites.EDISID = Sites.EDISID
	AND Sites.Hidden = 0
	GROUP BY UserSites.EDISID
	HAVING MAX(CASE WHEN UserType = 1 THEN UserID ELSE 0 END) IN
	(
		SELECT MAX(CASE WHEN UserType = 1 THEN UserID ELSE 0 END) AS RMID
		FROM UserSites
		JOIN Users ON Users.ID = UserSites.UserID
		JOIN Sites ON Sites.EDISID = UserSites.EDISID
		WHERE UserSites.EDISID = Sites.EDISID
		AND Sites.Hidden = 0
		GROUP BY UserSites.EDISID
		HAVING MAX(CASE WHEN UserType = 2 THEN UserID ELSE 0 END) = @UserID
	)
	
END

SELECT TOP 1 @CurrentPeriod = Period, @CurrentYear = PeriodYear, @CurrentPeriodWeeks = PeriodWeeks
FROM dbo.PubcoCalendars
WHERE Processed = 1
ORDER BY FromWC DESC

INSERT INTO #LastThreePeriods
SELECT TOP 3 PeriodNumber, Period
FROM dbo.PubcoCalendars
WHERE Processed = 1
ORDER BY ToWC DESC

SELECT @LastThreePeriods = ISNULL(@LastThreePeriods, '') + '[P' + CAST(PeriodNumber AS VARCHAR) + '],'
FROM #LastThreePeriods
ORDER BY Period ASC

SET @LastThreePeriods = LEFT(@LastThreePeriods, LEN(@LastThreePeriods) - 1)

SELECT @PeriodCount = COUNT(DISTINCT PeriodNumber) 
FROM PubcoCalendars

SET @SQL = 'INSERT INTO #LastTwelvePeriods
SELECT TOP ' + CAST(@PeriodCount AS VARCHAR) + ' PeriodNumber, Period
FROM dbo.PubcoCalendars
WHERE Processed = 1
ORDER BY ToWC DESC'

EXEC (@SQL)

SELECT @LastTwelvePeriods = ISNULL(@LastTwelvePeriods, '') + '[P' + CAST(PeriodNumber AS VARCHAR) + '],'
FROM #LastTwelvePeriods
ORDER BY Period ASC

SET @LastTwelvePeriods = LEFT(@LastTwelvePeriods, LEN(@LastTwelvePeriods) - 1)

INSERT INTO #RedsThisYear
SELECT	Users.[ID],
		Users.UserType,
		Users.UserName,
		Reds.DatabaseID,
		Reds.EDISID,
		Reds.Period,
		CASE WHEN Reds.CD IS NULL THEN NULL ELSE Reds.CD * -1 END,
		Reds.PeriodDispensed,
		PubcoCalendars.PeriodYear,
		PubcoCalendars.PeriodWeeks,
		'P' + CAST(PubcoCalendars.PeriodNumber AS VARCHAR),
		Areas.[Description] AS Area
FROM dbo.Reds AS Reds
JOIN dbo.PubcoCalendars ON PubcoCalendars.Period = Reds.Period
JOIN dbo.Sites ON Sites.EDISID = Reds.EDISID
JOIN dbo.Areas ON Areas.ID = Sites.AreaID
JOIN UserSites ON UserSites.EDISID = Reds.EDISID
JOIN Users ON Users.[ID] = UserSites.UserID
LEFT JOIN (	SELECT DISTINCT EDISID
			FROM dbo.SiteProperties
			WHERE PropertyID = @ExcludeFromRedsPropertyID
) AS SitesToExclude ON SitesToExclude.EDISID = Reds.EDISID
WHERE UserType IN (CASE WHEN @UserTypeID IN (1, 2) THEN 2 END)
AND (Reds.RunCode = 1 OR Reds.RunCode IS NULL)
AND PubcoCalendars.Period IN (SELECT Period FROM #LastTwelvePeriods)
AND Sites.Hidden = 0
AND (Sites.Region = @RegionID OR @RegionID IS NULL)
AND (Sites.EDISID IN (SELECT EDISID FROM #UserPeerSites)) -- OR @UserTypeID <> 2)
AND InsufficientData = 0
AND (SitesToExclude.EDISID IS NULL)

SET @SQL = 'SELECT DatabaseID, UserID, LoggedInUser, UserType, Area, [Manager], ' + @LastTwelvePeriods +
' FROM (
	SELECT	Reds.DatabaseID,
			Reds.Area,
			Reds.UserID,
			CASE WHEN Reds.UserID = ' + CAST(@UserID AS VARCHAR) + ' THEN 1 ELSE 0 END AS LoggedInUser,
			Reds.UserType,
			Reds.UserName AS [Manager],
			Reds.PeriodNumber,
			ROUND(SUM(Reds.CD)/36.0, 0) AS PeriodCD
	FROM #RedsThisYear AS Reds
	GROUP BY Reds.DatabaseID, Reds.Area, Reds.UserID, CASE WHEN Reds.UserID = ' + CAST(@UserID AS VARCHAR) + ' THEN 1 ELSE 0 END, Reds.UserType, Reds.UserName, Reds.PeriodNumber
) AS SubUserOverview
PIVOT
(
	SUM(PeriodCD) FOR PeriodNumber IN (' + @LastTwelvePeriods + ')
) AS pvt
ORDER BY LoggedInUser DESC, [Manager]'

EXEC (@SQL)

SET @SQL = 'SELECT DatabaseID, UserID, LoggedInUser, UserType, Area, [Manager], ' + @LastTwelvePeriods +
' FROM (
	SELECT	Reds.DatabaseID,
			Reds.Area,
			Reds.UserID,
			CASE WHEN Reds.UserID = ' + CAST(@UserID AS VARCHAR) + ' THEN 1 ELSE 0 END AS LoggedInUser,
			Reds.UserType,
			Reds.UserName AS [Manager],
			Reds.PeriodNumber,
			SUM(Reds.CD) / SUM(Reds.PeriodDispensed) AS [Deficit as % of Dispense]
	FROM #RedsThisYear AS Reds
	GROUP BY Reds.DatabaseID, Reds.Area, Reds.UserID, CASE WHEN Reds.UserID = ' + CAST(@UserID AS VARCHAR) + ' THEN 1 ELSE 0 END, Reds.UserType, Reds.UserName, Reds.PeriodNumber
) AS SubUserOverview
PIVOT
(
	SUM([Deficit as % of Dispense]) FOR PeriodNumber IN (' + @LastTwelvePeriods + ')
) AS pvt
ORDER BY LoggedInUser DESC, [Manager]'

EXEC (@SQL)

SET @SQL = 'SELECT DatabaseID, UserID, LoggedInUser, UserType, Area, [Manager], ' + @LastThreePeriods +
' FROM (
	SELECT	Reds.DatabaseID,
			Reds.Area,
			Reds.UserID,
			CASE WHEN Reds.UserID = ' + CAST(@UserID AS VARCHAR) + ' THEN 1 ELSE 0 END AS LoggedInUser,
			Reds.UserType,
			Reds.UserName AS [Manager],
			Reds.PeriodNumber,
			ROUND(SUM(Reds.CD)/36.0, 0) AS PeriodCD
	FROM #RedsThisYear AS Reds
	GROUP BY Reds.DatabaseID, Reds.Area, Reds.UserID, CASE WHEN Reds.UserID = ' + CAST(@UserID AS VARCHAR) + ' THEN 1 ELSE 0 END, Reds.UserType, Reds.UserName, Reds.PeriodNumber
) AS SubUserOverview
PIVOT
(
	SUM(PeriodCD) FOR PeriodNumber IN (' + @LastThreePeriods + ')
) AS pvt
ORDER BY LoggedInUser DESC, [Manager]'

EXEC (@SQL)

SELECT	Reds.DatabaseID,
		Reds.Area,
		Reds.UserID,
		CASE WHEN Reds.UserID = @UserID THEN 1 ELSE 0 END AS LoggedInUser,
		Reds.UserType,
		Reds.UserName AS [Manager],
		ROUND(SUM(CASE WHEN Reds.Period = @CurrentPeriod THEN Reds.CD/36.0 ELSE 0 END), 0) AS [CD This Period],
		ROUND(SUM(CASE WHEN Reds.Period = @CurrentPeriod THEN Reds.CD/36.0 ELSE 0 END) * ISNULL(@CDCashValue, 0), 0) AS [Value of CD This Period],
		ROUND(SUM(CASE WHEN Reds.Period = @CurrentPeriod THEN 1 ELSE 0 END), 2) AS [Number of Sites],
		ROUND(SUM(CASE WHEN Reds.Period = @CurrentPeriod AND Reds.CD > 0 THEN 1 ELSE 0 END), 2) AS [Number of Sites with CD],
		ROUND(SUM(CASE WHEN Reds.Period = @CurrentPeriod AND Reds.CD >= @HighCDValue THEN 1 ELSE 0 END), 2) AS [Number of Sites with High CD Value]
FROM #RedsThisYear AS Reds
GROUP BY Reds.DatabaseID, Reds.Area, Reds.UserID, CASE WHEN Reds.UserID = @UserID THEN 1 ELSE 0 END, Reds.UserType, Reds.UserName
ORDER BY CASE WHEN Reds.UserID = @UserID THEN 1 ELSE 0 END DESC, Reds.UserName

SET @SQL = 'SELECT DatabaseID, UserID, LoggedOnUser, UserType, Area, Manager, ' + @LastTwelvePeriods +
' FROM (
	SELECT	Reds.DatabaseID, ' +
			CAST(@UserID AS VARCHAR) + ' AS UserID,
			1 AS LoggedOnUser, ' +
			CAST(@UserTypeID AS VARCHAR) + ' AS UserType,
			'''' AS Area,
			'''' AS Manager,
			Reds.PeriodNumber,
			SUM(Reds.CD) / SUM(Reds.PeriodDispensed) AS [Deficit as % of Dispense]
	FROM #RedsThisYear AS Reds
	GROUP BY Reds.DatabaseID, Reds.PeriodNumber
) AS SubUserOverview
PIVOT
(
	SUM([Deficit as % of Dispense]) FOR PeriodNumber IN (' + @LastTwelvePeriods + ')
) AS pvt'

EXEC (@SQL)

DROP TABLE #UserPeerSites
DROP TABLE #RedsThisYear
DROP TABLE #LastThreePeriods
DROP TABLE #LastTwelvePeriods

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetWebUserCDSubUserOverview] TO PUBLIC
    AS [dbo];

