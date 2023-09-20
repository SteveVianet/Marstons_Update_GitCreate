CREATE PROCEDURE zRS_ExecSummaryYOY

AS

SET NOCOUNT ON

CREATE TABLE #LastTwelvePeriods(PeriodNumber INT, Period VARCHAR(10))
CREATE TABLE #SitesToExclude(EDISID INT)
CREATE TABLE #SiteUsers(EDISID INT, RMName VARCHAR(100), BDMName VARCHAR(100))


DECLARE @ExcludeFromRedsPropertyID INT
DECLARE @PeriodCount INT
DECLARE @SQL VARCHAR(8000)


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


INSERT INTO #SiteUsers

(EDISID)

SELECT EDISID

FROM dbo.Sites

WHERE Hidden = 0

 

UPDATE #SiteUsers

SET    BDMName = BDMUser.UserName,

       RMName = RMUser.UserName

FROM (

       SELECT UserSites.EDISID,

             MAX(CASE WHEN UserType = 2 THEN UserID ELSE 0 END) AS BDMID,

              MAX(CASE WHEN UserType = 1 THEN UserID ELSE 0 END) AS RMID

       FROM UserSites

       JOIN Users ON Users.ID = UserSites.UserID

       JOIN #SiteUsers AS Sites ON UserSites.EDISID = Sites.EDISID

       WHERE UserType IN (1,2) AND UserSites.EDISID = Sites.EDISID

       GROUP BY UserSites.EDISID

) AS SiteManagers

JOIN #SiteUsers AS Sites ON Sites.EDISID = SiteManagers.EDISID

JOIN Users AS BDMUser ON BDMUser.ID = SiteManagers.BDMID

JOIN Users AS RMUser ON RMUser.ID = SiteManagers.RMID


------------------------------------------------------------------------------

SELECT	Users.RMName
		,Users.BDMName
		,Reds.EDISID
		,Reds.PeriodWeeks AS PeriodWeeks
		,PubcoCalendars.PeriodYear AS PeriodYear
		,PubcoCalendars.PeriodNumber AS PeriodNumber
		,RedsLY.Period                           AS     LYPeriod
		,Reds.Period                         AS     TYPeriod
		,RedsLY.PeriodDelivered          AS  DelLY
		,Reds.PeriodDelivered            AS  DelTY
		,RedsLY.PeriodDispensed          AS  DisLY         
		,Reds.PeriodDispensed            AS  DisTY
		,RedsLY.CD                               AS     CDLY
		,Reds.CD                                 AS     CDTY

FROM Reds

JOIN PubcoCalendars	ON	Reds.Period		=	PubcoCalendars.Period

JOIN Reds AS RedsLY	ON	Reds.EDISID		=	RedsLY.EDISID

					AND	RedsLY.Period	=	PubcoCalendars.PeriodLY

JOIN #LastTwelvePeriods AS RollingYear ON RollingYear.Period = Reds.Period

JOIN #SiteUsers	AS Users ON Users.EDISID = Reds.EDISID

       
WHERE (Reds.RunCode = 1 OR Reds.RunCode IS NULL)

AND      (RedsLY.RunCode = 1 OR RedsLY.RunCode IS NULL)

AND (Reds.InsufficientData = 0 AND RedsLY.InsufficientData = 0)

AND Reds.EDISID NOT IN
						 (SELECT EDISID
						  FROM #SitesToExclude)


DROP TABLE #SitesToExclude
DROP TABLE #LastTwelvePeriods
DROP TABLE #SiteUsers
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[zRS_ExecSummaryYOY] TO PUBLIC
    AS [dbo];

