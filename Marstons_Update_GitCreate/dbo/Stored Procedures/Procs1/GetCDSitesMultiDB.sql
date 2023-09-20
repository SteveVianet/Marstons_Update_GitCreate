﻿CREATE PROCEDURE [dbo].[GetCDSitesMultiDB]
	@ReportType VARCHAR(100),
	@ScheduleName VARCHAR(255) = NULL,
	@UserID INT = NULL,
	@SiteID VARCHAR(100) = NULL
AS

--exec "TestA"."dbo"."GetCDSites";1 'User',0,181,NULL
--exec "TestB"."dbo"."GetCDSites";1 'User',0,192,NULL

--DECLARE	@ReportType VARCHAR(100) = 'Schedule'
--DECLARE	@ScheduleName VARCHAR(255) = '!All Sites!'
--DECLARE	@UserID INT = 0
--DECLARE	@SiteID VARCHAR(100) = NULL

CREATE TABLE #ReportSites (EDISID int)
IF @ReportType = 'Schedule'
	BEGIN
		INSERT INTO #ReportSites
		SELECT DISTINCT ss.EDISID
        FROM ScheduleSites ss
        JOIN Schedules s ON ss.ScheduleID = s.ID
		WHERE (s.[Description] = @ScheduleName)
	END

ELSE IF @ReportType = 'User'
	BEGIN
		INSERT INTO #ReportSites
		SELECT DISTINCT us.EDISID FROM UserSites us
		WHERE (UserID = @UserID)
	END

ELSE IF @ReportType = 'Site'
	BEGIN
		INSERT INTO #ReportSites
		SELECT s.EDISID FROM Sites s
		WHERE (SiteID = @SiteID)

END

CREATE TABLE #LastTwelvePeriods(PeriodNumber INT, Period VARCHAR(10))
CREATE TABLE #Sites(EDISID INT, SiteID VARCHAR(50), Name VARCHAR(100), Address1 VARCHAR(100), Address2 VARCHAR(100), Address3 VARCHAR(100), Address4 VARCHAR(100), PostCode VARCHAR(20), RMName VARCHAR(100), BDMName VARCHAR(100) , CMName VARCHAR (100))
CREATE TABLE #PeriodYears(PeriodYear VARCHAR(5))
CREATE TABLE #SitesToExclude(EDISID INT)
CREATE TABLE #RedsYOY (EDISID INT,PeriodWeeks INT, PeriodYear INT, PeriodNumber INT,LYPerioD VARCHAR(10), TYPeriod VARCHAR(10),DelLY FLOAT,DelTY FLOAT,DisLY FLOAT, DisTY FLOAT, CDLY FLOAT, CDTY FLOAT)

DECLARE @PeriodPivot VARCHAR(8000) = ''
DECLARE @SQL VARCHAR(8000)
DECLARE @CustomerID INT
DECLARE @ExcludeFromRedsPropertyID INT
DECLARE @LastPeriod VARCHAR(50)
DECLARE @PeriodCount INT

SELECT @PeriodCount = COUNT(DISTINCT PeriodNumber)
FROM PubcoCalendars

SET @SQL = 'INSERT INTO #LastTwelvePeriods
SELECT TOP ' + CAST(@PeriodCount AS VARCHAR) + ' PeriodNumber, Period
FROM dbo.PubcoCalendars
WHERE Processed = 1
ORDER BY ToWC DESC'

EXEC (@SQL)

SELECT @ExcludeFromRedsPropertyID = [ID]
FROM dbo.Properties
WHERE Name = 'Exclude From Reds'

-- Get the last two financial years for report (note: assumes the data is in year format like "1112" and the report needs the last two years of data)
INSERT INTO #PeriodYears

SELECT DISTINCT TOP 2 PeriodYear
FROM dbo.PubcoCalendars
WHERE Processed = 1
ORDER BY PeriodYear DESC

-- Get last period
SELECT TOP 1 @LastPeriod = Period
FROM dbo.PubcoCalendars
WHERE Processed = 1
ORDER BY ToWC DESC

-- SITE DETAILS**************************
INSERT INTO #Sites
(EDISID, SiteID, Name, Address1, Address2, Address3, Address4, PostCode)
SELECT EDISID, SiteID, Name, Address1, Address2, Address3, Address4, PostCode
FROM dbo.Sites
WHERE Hidden = 0
AND EDISID IN (SELECT EDISID FROM #ReportSites)

UPDATE #Sites
SET
BDMName = BDMUser.UserName,
RMName = RMUser.UserName,
CMName = CMUser.UserName
FROM (
	SELECT UserSites.EDISID,
	MAX(CASE WHEN UserType = 2 THEN UserID ELSE 0 END) AS BDMID,
	MAX(CASE WHEN UserType = 1 THEN UserID ELSE 0 END) AS RMID,
	MAX(CASE WHEN UserType = 9 THEN UserID ELSE 0 END) AS CMID
	FROM UserSites
	JOIN Users ON Users.ID = UserSites.UserID
	JOIN #Sites AS Sites ON UserSites.EDISID = Sites.EDISID
	WHERE UserType IN (1,2,9) AND UserSites.EDISID = Sites.EDISID
	AND Sites.EDISID IN (SELECT EDISID FROM #ReportSites)
	GROUP BY UserSites.EDISID
) AS SiteManagers
JOIN #Sites AS Sites ON Sites.EDISID = SiteManagers.EDISID
JOIN Users AS BDMUser ON BDMUser.ID = SiteManagers.BDMID
JOIN Users AS RMUser ON RMUser.ID = SiteManagers.RMID
JOIN Users AS CMUser ON CMUser.ID = SiteManagers.CMID

-- Build table of EDISIDs to exclude from report, where CD value is NULL for every period
INSERT INTO #SitesToExclude
SELECT Reds.EDISID
FROM dbo.Reds AS Reds
JOIN dbo.PubcoCalendars AS PubcoCalendars ON PubcoCalendars.Period = Reds.Period AND PubcoCalendars.DatabaseID = Reds.DatabaseID
WHERE Processed = 1
AND PeriodYear IN
(
	SELECT PeriodYear
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

INSERT INTO #RedsYOY
SELECT
	 Reds.EDISID
	,Reds.PeriodWeeks				AS PeriodWeeks
	,PubcoCalendars.PeriodYear		AS PeriodYear
	,PubcoCalendars.PeriodNumber	AS PeriodNumber
	,RedsLY.Period AS LYPeriod
	,Reds.Period					AS TYPeriod
	,RedsLY.PeriodDelivered          AS  DelLY
	,Reds.PeriodDelivered			AS DelTY
	,RedsLY.PeriodDispensed          AS  DisLY
	,Reds.PeriodDispensed			AS DisTY
	,RedsLY.CD          AS  CDLY
	,Reds.CD						AS CDTY
FROM Reds
JOIN PubcoCalendars ON Reds.Period = PubcoCalendars.Period
JOIN #LastTwelvePeriods AS RollingYear ON RollingYear.Period = Reds.Period
LEFT JOIN Reds AS RedsLY ON	Reds.EDISID	= RedsLY.EDISID
					AND	RedsLY.Period = PubcoCalendars.PeriodLY
WHERE (Reds.RunCode = 1 OR Reds.RunCode IS NULL)
AND (RedsLY.RunCode = 1 OR RedsLY.RunCode IS NULL)
AND Reds.InsufficientData = 0
AND Reds.EDISID IN (SELECT EDISID FROM #ReportSites)

-- THE SELECT***************
SELECT
	 Sites.RMName
	,Sites.BDMName
	,Sites.CMName
	,Sites.SiteID
	,Sites.Name
	,Sites.Address1
	,Sites.Address2
	,Sites.Address3
	,Sites.Address4
	,Sites.PostCode
	,CASE (isnumeric(SUBSTRING(PostCode , 2 , 1))) WHEN 1
		THEN LEFT (PostCode , 1)
		ELSE LEFT (PostCode , 2)   END           AS AreaCode
	,AreaName
	,Reds.PeriodWeeks
	,Reds.PeriodYear
	,Reds.PeriodNumber
	,Reds.LYPerioD
	,Reds.TYPeriod
	,Reds.DelLY
	,Reds.DelTY
	,Reds.DisLY
	,Reds.DisTY
	,Reds.CDLY
	,Reds.CDTY
   ,CAST(CASE WHEN Reds.TYPeriod = @LastPeriod THEN 1 ELSE 0 END AS BIT)  AS CurrentPeriod
FROM #Sites AS Sites
JOIN #RedsYOY AS Reds ON Reds.EDISID = Sites.EDISID
LEFT JOIN [SQL1\SQL1].[ServiceLogger].[dbo].[PostcodeAreas] AS PostcodeAreas      ON       PostcodeAreas.PostcodeArea = CASE (isnumeric(SUBSTRING(PostCode , 2 , 1))) WHEN 1  THEN LEFT (PostCode , 1)END
WHERE Sites.EDISID NOT IN (SELECT EDISID FROM #SitesToExclude)

ORDER BY RMName, BDMName, SiteID, PeriodYear, PeriodNumber

--DROPS
DROP TABLE #Sites
DROP TABLE #PeriodYears
DROP TABLE #SitesToExclude
DROP TABLE #RedsYOY
DROP TABLE #LastTwelvePeriods
DROP TABLE #ReportSites


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetCDSitesMultiDB] TO PUBLIC
    AS [dbo];

