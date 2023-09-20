CREATE PROCEDURE [dbo].[GetCDSitesReport]
AS

SET NOCOUNT ON

CREATE TABLE #Sites(EDISID INT, SiteID VARCHAR(50), Name VARCHAR(100), Address1 VARCHAR(100), Address2 VARCHAR(100), Address3 VARCHAR(100), Address4 VARCHAR(100), PostCode VARCHAR(20), RMName VARCHAR(100), BDMName VARCHAR(100))
CREATE TABLE #PeriodYears(PeriodYear VARCHAR(5))
CREATE TABLE #SitesToExclude(EDISID INT)

DECLARE @PeriodPivot VARCHAR(8000) = ''
DECLARE @SQL VARCHAR(8000)
DECLARE @CustomerID INT
DECLARE @ExcludeFromRedsPropertyID INT
DECLARE @LastPeriod VARCHAR(50)

-- Get customer/database ID
SELECT @CustomerID = CAST(PropertyValue AS INTEGER)
FROM dbo.Configuration
WHERE PropertyName = 'Service Owner ID'

SELECT @ExcludeFromRedsPropertyID = [ID]
FROM dbo.Properties
WHERE Name = 'Exclude From Reds'

-- Get the last two financial years for report (note: assumes the data is in year format like "1112" and the report needs the last two years of data)
INSERT INTO #PeriodYears
SELECT DISTINCT TOP 2 PeriodYear
FROM dbo.PubcoCalendars
WHERE Processed = 1
ORDER BY PeriodYear DESC

-- Concatenate all the available periodnames for use in the upcoming pivot
SELECT @PeriodPivot = ISNULL(@PeriodPivot, '') + '[' + Period + '],'
FROM dbo.PubcoCalendars 
WHERE Processed = 1
AND PeriodYear IN 
(	SELECT PeriodYear
	FROM #PeriodYears
)
ORDER BY Period

-- Remove trailing comma
SET @PeriodPivot = LEFT(@PeriodPivot, LEN(@PeriodPivot) - 1)

-- Get last period
SELECT TOP 1 @LastPeriod = Period
FROM dbo.PubcoCalendars
WHERE Processed = 1
ORDER BY ToWC DESC

-- Insert sites into temporary table. Using the real Sites table messes up the pivot because of the text field "Comment"
INSERT INTO #Sites
(EDISID, SiteID, Name, Address1, Address2, Address3, Address4, PostCode)
SELECT EDISID, SiteID, Name, Address1, Address2, Address3, Address4, PostCode
FROM dbo.Sites
WHERE Hidden = 0

UPDATE #Sites
SET	BDMName = BDMUser.UserName,
	RMName = RMUser.UserName
FROM (
	SELECT UserSites.EDISID,
	 	MAX(CASE WHEN UserType = 2 THEN UserID ELSE 0 END) AS BDMID,
		MAX(CASE WHEN UserType = 1 THEN UserID ELSE 0 END) AS RMID
	FROM UserSites
	JOIN Users ON Users.ID = UserSites.UserID
	JOIN #Sites AS Sites ON UserSites.EDISID = Sites.EDISID
	WHERE UserType IN (1,2) AND UserSites.EDISID = Sites.EDISID
	GROUP BY UserSites.EDISID
) AS SiteManagers
JOIN #Sites AS Sites ON Sites.EDISID = SiteManagers.EDISID
JOIN Users AS BDMUser ON BDMUser.ID = SiteManagers.BDMID
JOIN Users AS RMUser ON RMUser.ID = SiteManagers.RMID

-- Build table of EDISIDs to exclude from report, where CD value is NULL for every period
INSERT INTO #SitesToExclude
SELECT Reds.EDISID
FROM dbo.Reds AS Reds
JOIN dbo.PubcoCalendars AS PubcoCalendars ON PubcoCalendars.Period = Reds.Period AND PubcoCalendars.DatabaseID = Reds.DatabaseID
WHERE Processed = 1
AND PeriodYear IN 
(	SELECT PeriodYear
	FROM #PeriodYears
)
GROUP BY Reds.EDISID
HAVING SUM(CD) IS NULL

INSERT INTO #SitesToExclude
SELECT EDISID
FROM dbo.Sites
WHERE EDISID IN (
	  SELECT EDISID
	  FROM SiteGroupSites
	  JOIN SiteGroups ON SiteGroups.ID = SiteGroupSites.SiteGroupID
	  WHERE TypeID = 1 AND IsPrimary <> 1
)

INSERT INTO #SitesToExclude
SELECT EDISID
FROM dbo.SiteProperties
WHERE PropertyID = @ExcludeFromRedsPropertyID

-- Build up SQL string so we can add the concatenated periods for the pivot
SET @SQL = 'SELECT RMName, BDMName, SiteID, Name, Address1, Address2, Address3, Address4, PostCode, ' + @PeriodPivot + ', Agreement, TieType, LastPeriodDroppedDispense FROM
(
SELECT	Sites.RMName,
		Sites.BDMName,
		Sites.SiteID,
		Sites.Name,
		Reds.Period,
		Reds.CD,
		Sites.Address1,
		Sites.Address2,
		Sites.Address3,
		Sites.Address4,
		Sites.PostCode,
		SiteLeaseType.Value AS Agreement,
		SiteTieType.Value AS TieType,
		SiteDroppedDispense.PeriodDispensed AS LastPeriodDroppedDispense
FROM #Sites AS Sites
JOIN (
	SELECT EDISID, Period, CD
	FROM dbo.Reds
	WHERE (RunCode = 1 OR RunCode IS NULL)
	AND InsufficientData = 0
) AS Reds ON Reds.EDISID = Sites.EDISID
LEFT JOIN (
	SELECT EDISID, PeriodDispensed
	FROM dbo.Reds
	WHERE Period = ''' + @LastPeriod + '''
	AND (RunCode = 1 OR RunCode IS NULL)
	AND InsufficientData = 0
) AS SiteDroppedDispense ON SiteDroppedDispense.EDISID = Sites.EDISID
LEFT JOIN (
	SELECT EDISID, Value
	FROM SiteProperties
	JOIN Properties ON Properties.[ID] = SiteProperties.PropertyID
	WHERE Properties.Name = ''Pub Co Lease Type''
) AS SiteLeaseType ON SiteLeaseType.EDISID = Sites.EDISID
LEFT JOIN (
	SELECT EDISID, Value
	FROM SiteProperties
	JOIN Properties ON Properties.[ID] = SiteProperties.PropertyID
	WHERE Properties.Name = ''Pub Co Tie Type''
) AS SiteTieType ON SiteTieType.EDISID = Sites.EDISID
WHERE Period IN
(
	SELECT Period
	FROM dbo.PubcoCalendars 
	WHERE PeriodYear IN 
	(	SELECT PeriodYear
		FROM #PeriodYears
	)
	AND Processed = 1
)
AND Sites.EDISID NOT IN
(
	SELECT EDISID FROM #SitesToExclude
)
) AS SiteData
PIVOT (SUM(CD) FOR Period IN (' + @PeriodPivot + ')) AS pvt
ORDER BY RMName, BDMName, SiteID'

-- Run the SQL
EXEC (@SQL)

-- Drop temporary tables
DROP TABLE #Sites
DROP TABLE #PeriodYears
DROP TABLE #SitesToExclude

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetCDSitesReport] TO PUBLIC
    AS [dbo];

