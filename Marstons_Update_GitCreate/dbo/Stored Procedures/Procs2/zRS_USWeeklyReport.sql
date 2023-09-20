CREATE PROCEDURE [dbo].[zRS_USWeeklyReport]

(
@From	DATE = NULL,
@To		DATE = NULL
)
AS

DECLARE curSites CURSOR FORWARD_ONLY READ_ONLY FOR
SELECT EDISID
FROM Sites
WHERE Hidden = 0 AND Quality = 1

DECLARE @EDISID				INT
DECLARE @SQL            NVARCHAR(1024)


CREATE TABLE #Yield
(
TradingDate		DATE,
Product			VARCHAR (250),
IsCask			BIT,
IsKeg			BIT,
IsMetric		BIT,
BeerMeasured	FLOAT,
BeerDispensed	FLOAT,
DrinksDispensed FLOAT,
BeerInLineCleaning	FLOAT,
Sold	FLOAT,
OperationalYield	FLOAT,
RetailYield			FLOAT,
OverallYield		FLOAT,
NumberOfLinesCleaned	INT,
LowPouringYieldErrThreshold FLOAT,
HighPouringYieldErrThreshold	FLOAT,
POSYieldCashValue			FLOAT,
CleaningCashValue			FLOAT,
PouringYieldCashValue		FLOAT,
Day							INT,
ProductID					INT,
)  

CREATE TABLE #AllYield
(
EDISID			INT DEFAULT NULL,
TradingDate		DATE,
Product			VARCHAR (250),
IsCask			BIT,
IsKeg			BIT,
IsMetric		BIT,
BeerMeasured	FLOAT,
BeerDispensed	FLOAT,
DrinksDispensed FLOAT,
BeerInLineCleaning	FLOAT,
Sold	FLOAT,
OperationalYield	FLOAT,
RetailYield			FLOAT,
OverallYield		FLOAT,
NumberOfLinesCleaned	INT,
LowPouringYieldErrThreshold FLOAT,
HighPouringYieldErrThreshold	FLOAT,
POSYieldCashValue			FLOAT,
CleaningCashValue			FLOAT,
PouringYieldCashValue		FLOAT,
Day							INT,
ProductID					INT
)  

OPEN curSites
FETCH NEXT FROM curSites INTO @EDISID

WHILE @@FETCH_STATUS = 0
BEGIN
     
	  
	 SET @SQL = 'INSERT INTO #Yield EXEC dbo.GetWebSiteYieldDaily ' + CAST(@EDISID AS VARCHAR) + ', ''' + CAST(@From AS VARCHAR) + ''', ''' + CAST(@To AS VARCHAR) + ''', 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1'		                               
	 PRINT @SQL
	 EXEC sp_executesql @SQL
	 
	 SET @SQL = 'INSERT INTO #AllYield SELECT ' + CAST(@EDISID AS VARCHAR) + ', * FROM #Yield'
	  PRINT @SQL
	 EXEC sp_executesql @SQL

	 DELETE FROM #Yield

      FETCH NEXT FROM curSites INTO @EDISID
END

CLOSE curSites
DEALLOCATE curSites                                    


SELECT #AllYield.EDISID
		,SiteID
		,Name
		,SUM(Sold)*19.2152	AS Sold
		,SUM(DrinksDispensed) AS DrinksDispensed
		,(SUM(Sold)*19.2152)-SUM(DrinksDispensed) AS Loss
		,POSYieldCashValue
		,PouringYieldCashValue
		,SUM(BeerMeasured)*19.2152 AS BeerMeasured
		,SUM(BeerDispensed)*19.2152 AS BeerDispensed
		,SUM(Sold)/SUM(BeerMeasured) AS OverallYield

FROM #AllYield

JOIN Sites ON Sites.EDISID = #AllYield.EDISID

GROUP BY #AllYield.EDISID
		,SiteID
		,Name
		,POSYieldCashValue
		,PouringYieldCashValue
		


DROP TABLE #AllYield
DROP TABLE #Yield


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[zRS_USWeeklyReport] TO PUBLIC
    AS [dbo];

