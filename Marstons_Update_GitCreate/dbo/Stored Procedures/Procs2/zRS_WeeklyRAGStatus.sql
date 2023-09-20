CREATE PROCEDURE [dbo].[zRS_WeeklyRAGStatus]
AS

SET NOCOUNT ON

SET DATEFIRST 1

DECLARE		@LastPeriod AS VARCHAR(10)
SELECT		@LastPeriod = MAX(Period) FROM Reds

DECLARE		@ExcludeFromRedsPropertyID INT
SELECT		@ExcludeFromRedsPropertyID = [ID] FROM dbo.Properties WHERE Name = 'Exclude From Reds'


DECLARE		@To AS DATE 
SELECT		@To = CAST(DATEADD(wk, DATEDIFF(wk,0,getdate()), -14) AS DATE)

DECLARE		@From AS DATE 
SELECT		@From = DATEADD(Wk, -3,  @To) 


-- Get current Calendar Period
DECLARE		@Foy DATE
DECLARE		@Loy DATE
SELECT		@Foy = DATEADD( yy, DATEDIFF(yy ,0, getdate()), 0 )
SELECT		@Loy = DATEADD(yy, DATEDIFF(yy,0,getdate()) + 1, -1)

CREATE TABLE #CurrentCalendarPeriod (Period VARCHAR(10))
INSERT INTO #CurrentCalendarPeriod
SELECT Period
FROM PubcoCalendars
WHERE ToWC >= @Foy AND ToWC <= @Loy
AND Processed = 1

-- Get current Financial Calendar Period
CREATE TABLE #CurrentFinancialCalendarPeriod (Period VARCHAR(10))
INSERT INTO #CurrentFinancialCalendarPeriod
SELECT Period
FROM PubcoCalendars
WHERE PeriodYear = 
(
	SELECT TOP 1 PeriodYear
	FROM PubcoCalendars
	WHERE ToWC >= GETDATE()
	ORDER BY ToWC
)
AND Processed = 1

-- Get total CD from Current Period
CREATE TABLE #RedsTotalCDFromYTD (SiteId VARCHAR(15), TotalCD FLOAT)
INSERT INTO #RedsTotalCDFromYTD
SELECT s.SiteID, SUM(r.CD) FROM Sites s
LEFT JOIN Reds r ON s.EDISID = r.EDISID
JOIN #CurrentCalendarPeriod p ON r.Period = p.Period
GROUP BY s.SiteID

-- Get total CD from Current Financial Period
CREATE TABLE #RedsTotalCDFromFinancialYTD (SiteId VARCHAR(15), TotalCD FLOAT)
INSERT INTO #RedsTotalCDFromFinancialYTD
SELECT s.SiteID, SUM(r.CD) FROM Sites s
LEFT JOIN Reds r ON s.EDISID = r.EDISID
JOIN #CurrentFinancialCalendarPeriod p ON r.Period = p.Period
GROUP BY s.SiteID

SELECT	BDMUsers.UserName						AS BDM
		,SiteID
		,Cleaning.Name							AS CleaningColour
		,Temperature.Name						AS TemperatureColour
		,Yield.Name								AS PouringYieldColour
		,Throughput.Name						AS ThroughputColour
		,LowThrough.#Lines						AS LowThroughputLines
		,Reds.CD
		,CleaningDispense.TotalDispense			AS TotalDispense
		,CleaningDispense.OverdueCleanDispense	AS UncleanDispense
		,tCD.TotalCD							AS TotalCDOfYTD
		,tFCD.TotalCD							AS TotalCDOfFYTD
FROM Sites

LEFT JOIN		SiteRankingCurrent	ON	SiteRankingCurrent.EDISID	=	Sites.EDISID
LEFT JOIN		Reds				ON	Reds.EDISID					=	Sites.EDISID 

LEFT JOIN		#RedsTotalCDFromYTD tCD					ON	Sites.SiteID	=	tCD.SiteId
LEFT JOIN		#RedsTotalCDFromFinancialYTD tFCD		ON	Sites.SiteID	=	tFCD.SiteId

LEFT JOIN		
	(	
		SELECT	UserSites.EDISID
 				,MAX(CASE WHEN Users.UserType = 1	THEN UserID ELSE 0 END) AS RODID
				,MAX(CASE WHEN Users.UserType = 2	THEN UserID ELSE 0 END) AS BDMID
				
		FROM UserSites
		
		JOIN Users ON Users.ID = UserSites.UserID
		WHERE Users.UserType IN (1,2)
		
		GROUP BY UserSites.EDISID
	
			 )	AS UsersTEMP ON UsersTEMP.EDISID = Sites.EDISID

LEFT JOIN		Users AS RODUsers	ON RODUsers.ID	= UsersTEMP.RODID
LEFT JOIN		Users AS BDMUsers	ON BDMUsers.ID	= UsersTEMP.BDMID

LEFT JOIN SiteRankingTypes AS Cleaning			ON Cleaning.ID		= SiteRankingCurrent.SiteCleaningTL
LEFT JOIN SiteRankingTypes AS Temperature		ON Temperature.ID	= SiteRankingCurrent.SiteTemperatureTL
LEFT JOIN SiteRankingTypes AS Yield				ON Yield.ID			= SiteRankingCurrent.SitePouringYieldTL
LEFT JOIN SiteRankingTypes AS Throughput		ON Throughput.ID	= SiteRankingCurrent.SiteThroughputTL

LEFT JOIN (
			SELECT EDISID
			,SUM(TotalDispense)/8			AS TotalDispense
			,SUM(OverdueCleanDispense)/8	AS OverdueCleanDispense
			FROM PeriodCacheCleaningDispense
			WHERE Date BETWEEN @From AND @To
			GROUP BY EDISID
		 )	AS CleaningDispense

	ON CleaningDispense.EDISID		= Sites.EDISID 

LEFT JOIN (
			SELECT EDISID
			,COUNT(EDISID) AS #Lines
 			FROM WebSiteTLThroughput
			GROUP BY EDISID
		   )
		   	 AS LowThrough ON LowThrough.EDISID = Sites.EDISID

LEFT JOIN SiteProperties	ON SiteProperties.EDISID		= Sites.EDISID   AND SiteProperties.PropertyID     = @ExcludeFromRedsPropertyID


WHERE Period = @LastPeriod

AND Hidden = 0

AND SiteProperties.Value IS Null

ORDER BY 
		BDMUsers.UserName

-- Clean temp tables
DROP TABLE #CurrentCalendarPeriod
DROP TABLE #CurrentFinancialCalendarPeriod
DROP TABLE #RedsTotalCDFromYTD
DROP TABLE #RedsTotalCDFromFinancialYTD
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[zRS_WeeklyRAGStatus] TO PUBLIC
    AS [dbo];

