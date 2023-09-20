
 

 

CREATE PROCEDURE [dbo].[zRS_YearonYear]

 

(

@FromLastyear DATETIME=NULL,

@ToLastYear DATETIME=NULL,

@FromThisYear DATETIME=NULL,

@ToThisYear DATETIME=NULL)

 

 

AS SET NOCOUNT ON

 

CREATE TABLE #XmasLastYear (SiteID VARCHAR (25) NOT NULL,Date DATE NOT NULL , DayofYear INT,Year INT, Description VARCHAR (100),Pints FLOAT ,ViaUnclean FLOAT, Yearname VARCHAR (25))

CREATE TABLE #XmasThisYear (SiteID VARCHAR (25) NOT NULL,Date DATE NOT NULL ,Dayofyear INT ,Year INT,  Description VARCHAR (100),Pints FLOAT ,ViaUnclean FLOAT , Yearname VARCHAR (25))

 

INSERT INTO #XmasLastYear

 

SELECT

Sites.SiteID

,Date

,DATEPART(DayofYear, Date)  AS 'DayofYear'

,DATEPART(Year, Date)  AS 'Year'

,ProductCategories.Description

,SUM(TotalDispense) AS Pints

,SUM(OverdueCleanDispense) AS ViaUnclean,

'LastYear' AS YearName

 

FROM [dbo].[PeriodCacheCleaningDispenseDaily]

 

JOIN ProductCategories ON ProductCategories.ID = [PeriodCacheCleaningDispenseDaily].CategoryID

JOIN Sites ON Sites.EDISID=[PeriodCacheCleaningDispenseDaily].EDISID

 

WHERE Date BETWEEN @FromLastyear AND @ToLastYear AND Sites.Hidden=0

 

GROUP BY Sites.SiteID,

Date,ProductCategories.Description

 

INSERT INTO #XmasThisYear

 

 

SELECT

Sites.SiteID

,Date

,DATEPART(dayofyear, Date) AS 'DayofYear'

,DATEPART(Year, Date)  AS 'Year'

,ProductCategories.Description

,SUM(TotalDispense) AS Pints

,SUM(OverdueCleanDispense) AS ViaUnclean,

'ThisYear' AS YearName

 

FROM [dbo].[PeriodCacheCleaningDispenseDaily]

 

JOIN ProductCategories ON ProductCategories.ID = [PeriodCacheCleaningDispenseDaily].CategoryID

JOIN Sites ON Sites.EDISID=[PeriodCacheCleaningDispenseDaily].EDISID

 

WHERE Date BETWEEN @FromThisYear AND @ToThisYear

AND Sites.Hidden=0

 

GROUP BY Sites.SiteID,

Date,ProductCategories.Description

 

--SELECT * FROM #XmasThisYear

--UNION ALL

--SELECT * FROM #XmasLastYear

 

SELECT * FROM #XmasThisYear

WHERE SiteID IN ((SELECT SiteID FROM #XmasThisYear INTERSECT SELECT SiteID FROM #XmasLastYear))

 

UNION ALL

 

SELECT * FROM #XmasLastYear

WHERE SiteID IN ((SELECT SiteID FROM #XmasThisYear INTERSECT SELECT SiteID FROM #XmasLastYear))

 

DROP TABLE #XmasLastYear

DROP TABLE #XmasThisYear
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[zRS_YearonYear] TO PUBLIC
    AS [dbo];

