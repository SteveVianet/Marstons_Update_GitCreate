



CREATE PROCEDURE [dbo].[GetWebUserCDOverview]
(
	@UserID				INT,
	@ShowOnlyLiveSites	BIT = 1
)
AS

SET NOCOUNT ON

DECLARE @DatabaseID INT
DECLARE @CurrentPeriod VARCHAR(50)
DECLARE @CurrentYear VARCHAR(5)
DECLARE @CurrentPeriodWeeks INT
DECLARE @CDCashValue FLOAT
DECLARE @HighCDValue FLOAT
DECLARE @ExcludeFromRedsPropertyID INT
DECLARE @UserHasAllSites BIT
DECLARE @UserTypeID INT
DECLARE @PeriodCount INT
DECLARE @LastTwelvePeriods VARCHAR(100)
DECLARE @TwelveMonthPeriodCalendar VARCHAR(100)
DECLARE @LastTwelveMonths VARCHAR(1000)
DECLARE @SQL VARCHAR(8000)

CREATE TABLE #Last2PeriodYears(PeriodYear VARCHAR(5))
CREATE TABLE #Last3PeriodYears(PeriodYear VARCHAR(5))
CREATE TABLE #LastTwelvePeriods(PeriodNumber INT, Period VARCHAR(10))
CREATE TABLE #Reds(DatabaseID INT, EDISID INT, Period VARCHAR(10), CD FLOAT, PeriodDispensed FLOAT, PeriodYear VARCHAR(10), PeriodWeeks INT, PeriodNumber VARCHAR(10), Region VARCHAR(100), RegionID INT)

SELECT @UserTypeID = UserType, @UserHasAllSites = AllSitesVisible
FROM dbo.Users
JOIN UserTypes ON UserTypes.[ID] = Users.UserType
WHERE Users.[ID] = @UserID

SELECT @DatabaseID = CAST(PropertyValue AS INTEGER)
FROM dbo.Configuration
WHERE PropertyName = 'Service Owner ID'

SELECT @CDCashValue = CAST(PropertyValue AS FLOAT)
FROM dbo.Configuration
WHERE PropertyName = 'Calculated Deficit Cash Value'

SELECT @HighCDValue = CAST(PropertyValue AS FLOAT)
FROM dbo.Configuration
WHERE PropertyName = 'Calculated Deficit High CD Threshold'

SELECT @ExcludeFromRedsPropertyID = [ID]
FROM dbo.Properties
WHERE Name = 'Exclude From Reds'

INSERT INTO #Last2PeriodYears
SELECT DISTINCT TOP 2 PeriodYear
FROM dbo.PubcoCalendars
WHERE Processed = 1
ORDER BY PeriodYear DESC

INSERT INTO #Last3PeriodYears
SELECT DISTINCT TOP 3 PeriodYear
FROM dbo.PubcoCalendars
WHERE Processed = 1
ORDER BY PeriodYear DESC

SELECT TOP 1 @CurrentPeriod = Period, @CurrentYear = PeriodYear, @CurrentPeriodWeeks = PeriodWeeks
FROM dbo.PubcoCalendars
WHERE Processed = 1
ORDER BY FromWC DESC

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

SELECT @TwelveMonthPeriodCalendar = ISNULL(@TwelveMonthPeriodCalendar, '') + '[P' + CAST(PeriodNumber AS VARCHAR) + '],'
FROM (SELECT DISTINCT PeriodNumber
	  FROM dbo.PubcoCalendars) AS PeriodNumbers
	  
SET @TwelveMonthPeriodCalendar = LEFT(@TwelveMonthPeriodCalendar, LEN(@TwelveMonthPeriodCalendar) - 1)

SELECT TOP 12 @LastTwelveMonths = ISNULL(@LastTwelveMonths, '') + '[' + CAST([Month] AS VARCHAR) + ' ' + CAST([Year] AS VARCHAR) + '],'
FROM (SELECT DISTINCT [Month], [Year], ToMonday FROM RedsMonthlyCDI) AS CDIMonths
WHERE ToMonday IN (SELECT DISTINCT TOP 12 ToMonday FROM RedsMonthlyCDI ORDER BY ToMonday DESC)
ORDER BY ToMonday ASC

SET @LastTwelveMonths = LEFT(@LastTwelveMonths, LEN(@LastTwelveMonths) - 1)

INSERT INTO #Reds
SELECT	Reds.DatabaseID,
		Reds.EDISID,
		Reds.Period,
		CASE WHEN Reds.CD IS NULL THEN NULL ELSE Reds.CD * -1 END,
		Reds.PeriodDispensed,
		PubcoCalendars.PeriodYear,
		PubcoCalendars.PeriodWeeks,
		'P' + CAST(PubcoCalendars.PeriodNumber AS VARCHAR),
		SitesList.Region,
		SitesList.RegionID
FROM dbo.Reds AS Reds
JOIN dbo.PubcoCalendars ON PubcoCalendars.Period = Reds.Period
JOIN #Last3PeriodYears AS Last3PeriodYears ON Last3PeriodYears.PeriodYear = PubcoCalendars.PeriodYear
JOIN (
	SELECT Sites.EDISID, Regions.[Description] AS Region, Regions.[ID] AS RegionID
	FROM Sites
	JOIN Regions ON Regions.[ID] = Sites.Region
	WHERE ((@UserHasAllSites = 1) OR (Sites.EDISID IN (SELECT EDISID FROM UserSites WHERE UserID = @UserID)))
	AND ((Sites.Hidden = 0 AND @ShowOnlyLiveSites = 1) OR @ShowOnlyLiveSites = 0)
) AS SitesList ON SitesList.EDISID = Reds.EDISID
LEFT JOIN (	SELECT DISTINCT EDISID
			FROM dbo.SiteProperties
			WHERE PropertyID = @ExcludeFromRedsPropertyID
) AS SitesToExclude ON SitesToExclude.EDISID = Reds.EDISID
WHERE (Reds.RunCode = 1 OR Reds.RunCode IS NULL) AND (SitesToExclude.EDISID IS NULL)
AND InsufficientData = 0

SELECT	Reds.DatabaseID,
		Reds.RegionID,
		Reds.Region,
		Users.[ID] AS UserID,
		Users.UserType,
		CASE WHEN Users.[ID] = @UserID THEN 1 ELSE 0 END AS LoggedInUser,
		Users.UserName AS [Manager],
		ROUND(SUM(CASE WHEN Reds.Period = @CurrentPeriod THEN Reds.CD/36.0 ELSE 0 END), 0) AS [CD This Period],
		ROUND(SUM(Reds.CD)/36.0, 0) AS [CD Year To Date],
		ROUND(SUM(CASE WHEN Reds.Period = @CurrentPeriod THEN Reds.CD/36.0 ELSE 0 END) * ISNULL(@CDCashValue, 0), 0) AS [Value of CD This Period],
		ROUND(SUM(Reds.CD)/36.0 * ISNULL(@CDCashValue, 0), 0) AS [Value of CD Year to Date],
		SUM(CASE WHEN Reds.Period = @CurrentPeriod THEN Reds.CD ELSE 0 END) / CASE WHEN SUM(CASE WHEN Reds.Period = @CurrentPeriod THEN Reds.PeriodDispensed ELSE 0 END) = 0 THEN 1 ELSE SUM(CASE WHEN Reds.Period = @CurrentPeriod THEN Reds.PeriodDispensed ELSE 0 END) END AS [CD as % of Dispensed Volume],
		ROUND(((SUM(CASE WHEN Reds.Period = @CurrentPeriod THEN Reds.CD ELSE 0 END) / 36.0) / CASE WHEN SUM(CASE WHEN Reds.Period = @CurrentPeriod THEN 1 ELSE 0 END) = 0 THEN 1 ELSE SUM(CASE WHEN Reds.Period = @CurrentPeriod THEN 1 ELSE 0 END) END) / @CurrentPeriodWeeks, 2) AS [Period CDI Value],
		ROUND(SUM(CASE WHEN Reds.Period = @CurrentPeriod THEN 1 ELSE 0 END), 2) AS [Number of Sites],
		ROUND(SUM(CASE WHEN Reds.Period = @CurrentPeriod AND Reds.CD > 0 THEN 1 ELSE 0 END), 2) AS [Number of Sites with CD],
		ROUND(SUM(CASE WHEN Reds.Period = @CurrentPeriod AND Reds.CD >= @HighCDValue THEN 1 ELSE 0 END), 2) AS [Number of Sites with High CD Value],
		ROUND(SUM(CASE WHEN Reds.Period = @CurrentPeriod THEN Reds.PeriodDispensed ELSE 0 END), 2) AS [Dispensed This Period],
		@CurrentPeriodWeeks AS CurrentPeriodWeeks
FROM #Reds AS Reds
JOIN UserSites ON UserSites.EDISID = Reds.EDISID
JOIN Users ON Users.[ID] = UserSites.UserID
WHERE UserType IN (CASE WHEN @UserTypeID IN (3, 4, 15) THEN 1 WHEN @UserTypeID = 1 THEN 2 END)
AND Reds.PeriodYear = @CurrentYear
GROUP BY Reds.DatabaseID, Reds.RegionID, Reds.Region, Users.[ID], Users.UserType, CASE WHEN Users.[ID] = @UserID THEN 1 ELSE 0 END, Users.UserName
ORDER BY Users.UserName

SET @SQL = 
'SELECT [Year], ' + @TwelveMonthPeriodCalendar +
' FROM (
SELECT	Reds.PeriodYear AS [Year],
		Reds.PeriodNumber AS PeriodNumber,
		ROUND(SUM(Reds.CD)/36.0, 0) AS PeriodCD
FROM #Reds AS Reds
JOIN #Last3PeriodYears AS Last3PeriodYears ON Last3PeriodYears.PeriodYear = Reds.PeriodYear
GROUP BY Reds.PeriodYear, Reds.PeriodNumber
) AS ThreeYearCD
PIVOT 
(
	SUM(PeriodCD) FOR PeriodNumber IN (' + @TwelveMonthPeriodCalendar + ')
) AS pvt
ORDER BY [Year]'

EXEC (@SQL)

SET @SQL =
'SELECT [Description], ' + @LastTwelvePeriods + 
' FROM
(
	SELECT ''Dispensed Volume'' AS [Description], ' + @LastTwelvePeriods +
	' FROM 
	(
		SELECT	Reds.PeriodNumber,
				ROUND(SUM(Reds.PeriodDispensed)/36.0, 0) AS [Dispensed Volume]
		FROM #Reds AS Reds
		WHERE Reds.Period IN (SELECT Period FROM #LastTwelvePeriods)
		GROUP BY Reds.PeriodNumber
	) AS PercentDispense
	PIVOT 
	(
		SUM([Dispensed Volume]) FOR PeriodNumber IN (' + @LastTwelvePeriods + ')
	) AS pvt
) AS test
UNION ALL
	(SELECT ''Calculated Deficit'', ' + @LastTwelvePeriods +
	' FROM 
	(
		SELECT	Reds.PeriodNumber,
				ROUND(SUM(Reds.CD)/36.0, 0) AS [Calculated Deficit]
		FROM #Reds AS Reds
		WHERE Reds.Period IN (SELECT Period FROM #LastTwelvePeriods)
		GROUP BY Reds.PeriodNumber
	) AS PercentDispense
	PIVOT 
	(
		SUM([Calculated Deficit]) FOR PeriodNumber IN (' + @LastTwelvePeriods + ')
	) AS pvt
)
UNION ALL
	(SELECT ''Deficit as % of Dispense'', ' + @LastTwelvePeriods +
	' FROM 
	(
		SELECT	Reds.PeriodNumber,
				ROUND((SUM(Reds.CD) / SUM(Reds.PeriodDispensed)) * 100, 2) AS [Deficit as % of Dispense]
		FROM #Reds AS Reds
		WHERE Reds.Period IN (SELECT Period FROM #LastTwelvePeriods)
		GROUP BY Reds.PeriodNumber
	) AS PercentDispense
	PIVOT 
	(
		SUM([Deficit as % of Dispense]) FOR PeriodNumber IN (' + @LastTwelvePeriods + ')
	) AS pvt
)'

EXEC (@SQL)

SET @SQL =
'SELECT [Year], ' + @TwelveMonthPeriodCalendar +
' FROM
(
SELECT	Reds.PeriodYear AS [Year],
		Reds.PeriodNumber,
		(SUM(Reds.CD) / SUM(Reds.PeriodDispensed)) AS CDPercentOfDispensed
FROM #Reds AS Reds 
JOIN #Last2PeriodYears AS Last2PeriodYears ON Last2PeriodYears.PeriodYear = Reds.PeriodYear
GROUP BY Reds.PeriodYear, Reds.PeriodNumber
) AS YearOnYearDispense
PIVOT 
(
	SUM(CDPercentOfDispensed) FOR PeriodNumber IN (' + @TwelveMonthPeriodCalendar + ')
) AS pvt'

EXEC (@SQL)

SET @SQL =
'SELECT [Year], ' + @TwelveMonthPeriodCalendar +
' FROM
(
SELECT	Reds.PeriodYear AS [Year],
		Reds.PeriodNumber,
		ROUND(((SUM(Reds.CD) / 36.0) / CASE WHEN COUNT(*) = 0 THEN 1 ELSE COUNT(*) END) / Reds.PeriodWeeks, 2) AS PeriodCDI
FROM #Reds AS Reds
JOIN #Last2PeriodYears AS Last2PeriodYears ON Last2PeriodYears.PeriodYear = Reds.PeriodYear 
GROUP BY Reds.PeriodYear, Reds.PeriodNumber, Reds.PeriodWeeks
) AS YearOnYearCDI
PIVOT 
(
	SUM(PeriodCDI) FOR PeriodNumber IN (' + @TwelveMonthPeriodCalendar + ')
) AS pvt'

EXEC (@SQL)

SET @SQL = 
'SELECT [Description], ' + @LastTwelveMonths +
' FROM (
SELECT CASE WHEN DatabaseID = 0 THEN ''Market'' ELSE ''Customer'' END AS [Description], CAST([Month] AS VARCHAR) + '' '' + CAST([Year] AS VARCHAR) AS TheDate, (CDI*-1) AS CDI
FROM RedsMonthlyCDI
WHERE ToMonday IN (SELECT DISTINCT TOP 12 ToMonday FROM RedsMonthlyCDI ORDER BY ToMonday DESC)
) AS ThreeYearCD
PIVOT 
(
	SUM(CDI) FOR TheDate IN (' + @LastTwelveMonths + ')
) AS pvt'

EXEC (@SQL)


SET @SQL =
'SELECT [Description], ' + @LastTwelvePeriods + ' FROM
(
	SELECT ''Number of Sites With Calculated Deficit'' AS [Description], ' + @LastTwelvePeriods + ' FROM
	(
	SELECT	Reds.PeriodNumber,
			SUM(CASE WHEN Reds.CD > 0 THEN 1 ELSE 0 END) AS [Number of Sites With Calculated Deficit]
	FROM #Reds AS Reds
	WHERE Reds.Period IN (SELECT Period FROM #LastTwelvePeriods)
	GROUP BY Reds.PeriodNumber
	) AS NoSites
	PIVOT 
	(
		SUM([Number of Sites With Calculated Deficit]) FOR PeriodNumber IN (' + @LastTwelvePeriods + ')
	) AS pvt
) AS Test1
UNION ALL
(
	SELECT ''Houses In Measure'' AS [Description], ' + @LastTwelvePeriods + ' FROM
	(
	SELECT	Reds.PeriodNumber,
			SUM(CASE WHEN Reds.CD IS NOT NULL THEN 1 ELSE 0 END) AS [Houses In Measure]
	FROM #Reds AS Reds
	WHERE Reds.Period IN (SELECT Period FROM #LastTwelvePeriods)
	GROUP BY Reds.PeriodNumber
	) AS HousesInMeasure
	PIVOT 
	(
		SUM([Houses In Measure]) FOR PeriodNumber IN (' + @LastTwelvePeriods + ')
	) AS pvt
)
UNION ALL
(
	SELECT ''% Sites with Calculated Deficit'' AS [Description], ' + @LastTwelvePeriods + ' FROM
	(
	SELECT	Reds.PeriodNumber,
			ROUND(SUM(CASE WHEN Reds.CD > 0 THEN 1 ELSE 0 END) / CAST(SUM(CASE WHEN Reds.CD IS NOT NULL THEN 1 ELSE 0 END) AS FLOAT) * 100, 2) AS [% Sites with Calculated Deficit]
	FROM #Reds AS Reds
	WHERE Reds.Period IN (SELECT Period FROM #LastTwelvePeriods)
	GROUP BY Reds.PeriodNumber
	) AS HousesInMeasure
	PIVOT 
	(
		SUM([% Sites with Calculated Deficit]) FOR PeriodNumber IN (' + @LastTwelvePeriods + ')
	) AS pvt
)'

EXEC (@SQL)

SET @SQL = 
'SELECT [Description], ' + @LastTwelvePeriods + ' FROM
(
    SELECT ''Average Weekly CD Per House'' AS [Description], ' + @LastTwelvePeriods + ' FROM
    (
    SELECT	Reds.PeriodNumber,
		    ROUND((SUM(Reds.CD)/36.0) / CAST(SUM(CASE WHEN Reds.CD > 0 THEN 1 ELSE 0 END) AS FLOAT) / CAST(Reds.PeriodWeeks AS FLOAT), 2) AS AverageWeeklyCDPerHouse
    FROM #Reds AS Reds
    WHERE Reds.Period IN (SELECT Period FROM #LastTwelvePeriods) AND Reds.CD > 0
    GROUP BY Reds.PeriodNumber, Reds.PeriodWeeks
    ) AS YearOnYearCDI
    PIVOT 
    (
	    SUM(AverageWeeklyCDPerHouse) FOR PeriodNumber IN (' + @LastTwelvePeriods + ')
    ) AS pvt
) AS Test1
UNION ALL
(
    SELECT ''Average % dispense outside tie'' AS [Description], ' + @LastTwelvePeriods + ' FROM
    (
    SELECT	Reds.PeriodNumber,
            ROUND((SUM(Reds.CD) / SUM(Reds.PeriodDispensed)) * 100, 2) AS [Average % Dispense outside tie]
    FROM #Reds AS Reds
    WHERE Reds.Period IN (SELECT Period FROM #LastTwelvePeriods) AND Reds.CD > 0
    GROUP BY Reds.PeriodNumber, Reds.PeriodWeeks
    ) AS YearOnYearCDI
    PIVOT 
    (
        SUM([Average % Dispense outside tie]) FOR PeriodNumber IN (' + @LastTwelvePeriods + ')
    ) AS pvt
)'

EXEC (@SQL)

DROP TABLE #LastTwelvePeriods
DROP TABLE #Last2PeriodYears
DROP TABLE #Last3PeriodYears
DROP TABLE #Reds

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetWebUserCDOverview] TO PUBLIC
    AS [dbo];

