CREATE PROCEDURE [dbo].[GetWebUserCDSiteList]
(
	@UserID				INT,
	@ShowOnlyLiveSites	BIT = 1,
	@ShowHighCDSites	BIT = 1
)
AS

SET NOCOUNT ON

DECLARE @HighCDValue FLOAT
DECLARE @ExcludeFromRedsPropertyID INT
DECLARE @CurrentPeriod VARCHAR(50)
DECLARE @LastThreePeriods VARCHAR(100)
DECLARE @SQL VARCHAR(8000)

CREATE TABLE #Reds(UserID INT, UserType INT, UserName VARCHAR(100), DatabaseID INT, EDISID INT, SiteID VARCHAR(50), Name VARCHAR(100), Town VARCHAR(100), BDM VARCHAR(100), CD FLOAT,  PeriodNumber VARCHAR(10))
CREATE TABLE #LastThreePeriods(PeriodNumber INT, Period VARCHAR(10))
CREATE TABLE #HighCDSites(EDISID INT)

SELECT @HighCDValue = CAST(PropertyValue AS FLOAT)
FROM dbo.Configuration
WHERE PropertyName = 'Calculated Deficit High CD Threshold'

SELECT @ExcludeFromRedsPropertyID = [ID]
FROM dbo.Properties
WHERE Name = 'Exclude From Reds'

SELECT TOP 1 @CurrentPeriod = Period
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

INSERT INTO #HighCDSites
SELECT EDISID
FROM Reds
WHERE Period = @CurrentPeriod
AND Reds.CD <= (@HighCDValue * -1)
AND (Reds.RunCode = 1 OR Reds.RunCode IS NULL)

INSERT INTO #Reds
SELECT	Users.[ID],
		Users.UserType,
		Users.UserName,
		Reds.DatabaseID,
		Reds.EDISID,
		Sites.SiteID,
		Sites.Name,
		CASE WHEN LEN(Sites.Address4) > 0 THEN Sites.Address4 ELSE Sites.Address3 END AS Town,
		BDMUsers.UserName,
		CASE WHEN Reds.CD IS NULL THEN NULL ELSE Reds.CD * -1 END,
		'P' + CAST(PubcoCalendars.PeriodNumber AS VARCHAR)
FROM dbo.Reds AS Reds
JOIN dbo.PubcoCalendars ON PubcoCalendars.Period = Reds.Period AND PubcoCalendars.Period IN (SELECT Period FROM #LastThreePeriods)
JOIN dbo.Sites ON Sites.EDISID = Reds.EDISID
JOIN UserSites ON UserSites.EDISID = Reds.EDISID AND UserSites.UserID = @UserID
LEFT JOIN (	SELECT	UserSites.EDISID,
	 				MAX(UserID) AS BDMID
			FROM UserSites
			JOIN Users ON Users.ID = UserSites.UserID
			WHERE UserType = 2
			GROUP BY UserSites.EDISID
) AS SiteBDMs ON SiteBDMs.EDISID = Sites.EDISID
JOIN Users AS BDMUsers ON BDMUsers.[ID] = SiteBDMs.BDMID
JOIN Users ON Users.[ID] = UserSites.UserID
LEFT JOIN #HighCDSites AS HighCDSites ON HighCDSites.EDISID = Reds.EDISID
LEFT JOIN (	SELECT DISTINCT EDISID
			FROM dbo.SiteProperties
			WHERE PropertyID = @ExcludeFromRedsPropertyID
) AS SitesToExclude ON SitesToExclude.EDISID = Reds.EDISID
WHERE (Reds.RunCode = 1 OR Reds.RunCode IS NULL)
AND Sites.Hidden = 0
AND (HighCDSites.EDISID IS NOT NULL OR @ShowHighCDSites = 0)
AND (SitesToExclude.EDISID IS NULL)

SET @SQL = 'SELECT DatabaseID, EDISID, SiteID, Name, Town, Manager, ' + @LastThreePeriods +
' FROM (
	SELECT	Reds.DatabaseID,
			Reds.EDISID,
			Reds.SiteID,
			Reds.Name,
			Reds.Town,
			Reds.BDM AS Manager,
			Reds.PeriodNumber,
			ROUND(SUM(Reds.CD), 2) AS PeriodCD
	FROM #Reds AS Reds
	GROUP BY Reds.DatabaseID, Reds.EDISID, Reds.SiteID, Reds.Name, Reds.Town, Reds.BDM, Reds.PeriodNumber
) AS SubUserOverview
PIVOT
(
	SUM(PeriodCD) FOR PeriodNumber IN (' + @LastThreePeriods + ')
) AS pvt
ORDER BY Name'

EXEC (@SQL)

DROP TABLE #Reds
DROP TABLE #LastThreePeriods
DROP TABLE #HighCDSites

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetWebUserCDSiteList] TO PUBLIC
    AS [dbo];

