CREATE PROCEDURE [dbo].[zRS_CAMKPI_REDsData]
AS

SET NOCOUNT ON

CREATE TABLE #SitesToExclude	(EDISID INT)
CREATE TABLE #PeriodYears		(PeriodYear VARCHAR(5))

DECLARE @SQL VARCHAR(8000)
DECLARE @ExcludeFromRedsPropertyID INT
DECLARE @BarrelCharge FLOAT

SELECT @ExcludeFromRedsPropertyID = [ID]
FROM dbo.Properties
WHERE Name = 'Exclude From Reds'


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


INSERT INTO #PeriodYears

	SELECT DISTINCT TOP 2 PeriodYear
	FROM dbo.PubcoCalendars
	WHERE Processed = 1
	ORDER BY PeriodYear DESC

SELECT @ExcludeFromRedsPropertyID = [ID]
FROM dbo.Properties
WHERE Name = 'Exclude From Reds'

SELECT @BarrelCharge = PropertyValue
FROM
Configuration 
WHERE PropertyName = 'Damages Per Barrel'

-- THE SELECT


SELECT	 
		BDMUsers.UserName+Period		AS [KEY]
		,RODUsers.UserName				AS RMName
		,BDMUsers.UserName				AS BDMName
		,CAMUsers.UserName				AS CAMName
		,Period
		,COUNT(Reds.EDISID)				AS RecCount
		,SUM (CASE WHEN Reds.CD <0 
				THEN 1 ELSE 0 END )		AS SiteinNeg
		,0 - SUM(CD)					AS TotalCD		
		,SUM(PeriodDelivered)/36		AS Deliv
		,SUM(PeriodDispensed)/36		AS Disp	
		,Reds.PeriodWeeks				AS Weeks
		,''								AS Blank
		,(0 - SUM(CD))/36*@BarrelCharge	AS [£Value]

FROM (
	SELECT  UserSites.EDISID,
 			MAX(CASE WHEN Users.UserType = 1	THEN UserID ELSE 0 END) AS RODID,
			MAX(CASE WHEN Users.UserType = 2	THEN UserID ELSE 0 END) AS BDMID,
			MAX(CASE WHEN Users.UserType = 9	THEN UserID ELSE 0 END) AS CAMID

	FROM UserSites

	JOIN Users ON Users.ID = UserSites.UserID
	WHERE Users.UserType IN (1,2,9)

	GROUP BY UserSites.EDISID

	) AS UsersTEMP

JOIN		Users	AS	RODUsers	ON	RODUsers.ID		=	UsersTEMP.RODID
JOIN		Users	AS	BDMUsers	ON	BDMUsers.ID		=	UsersTEMP.BDMID
JOIN		Users	AS	CAMUsers	ON	CAMUsers.ID		=	UsersTEMP.CAMID
RIGHT JOIN	Reds					ON	Reds.EDISID		=	UsersTEMP.EDISID
JOIN		Sites					ON	Sites.EDISID	=	UsersTEMP.EDISID


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

AND Hidden = 0
AND InsufficientData = 0


GROUP BY RODUsers.UserName
		,BDMUsers.UserName
		,CAMUsers.UserName
		,Reds.Period
		,Reds.PeriodWeeks

ORDER BY RODUsers.UserName
		,BDMUsers.UserName
		,Period

DROP TABLE #PeriodYears
DROP TABLE #SitesToExclude

GRANT EXECUTE ON [zRS_CAMKPI_REDsData] TO public