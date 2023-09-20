CREATE PROCEDURE [art].[sb_LowThroughput]		-- I think this will apply to the art schema that's been created

(
	@StartDate DATETIME = NULL
	,@EndDate DATETIME = NULL
	,@Volume INT = NULL							-- I'm assuming all parameters need including here
)

AS SET NOCOUNT ON

SELECT Sites.SiteID
	,Sites.Name
	,Sites.PostCode
	,PCTDW.EDISID
    ,Products.Description AS 'Productdescr'
    ,ProductCategories.Description AS 'Categorydescr'
    ,[Pump]
    ,[ProductID]
    ,AVG (Volume ) AS AverageVolume
    ,COUNT (Volume ) AS Weeks
    ,SUM (Volume) AS Total
    ,CASE WHEN AVG ([Volume] ) <= @Volume THEN 1 ELSE 0 END AS 'Lowthroughtputmeter'
    ,MYUsers.RODName
    ,MYUsers.BDMName
    ,MYUsers.CAMName

  FROM [dbo].[PeriodCacheTradingDispenseWeekly] AS PCTDW

  JOIN Sites ON Sites.EDISID = PCTDW.EDISID
  JOIN Products ON Products.ID = PCTDW.ProductID
  JOIN ProductCategories ON Products.CategoryID = ProductCategories.ID
  JOIN Owners ON Sites.OwnerID = Owners.ID

JOIN
	( 
--------------Retrieve EDISID, ROD Name, BDM name and CAM Name----------------------------------------------
	SELECT Sites.EDISID
	,RODUsers.UserName AS RODName
	,BDMUsers.UserName AS BDMName
	,CAMUsers.UserName AS CAMName
	FROM
		(
--------------------------Retrieve EDISID, RODID, BDMID and CAMID----------------------------------------
		SELECT UserSites.EDISID, 
		MAX(CASE WHEN Users.UserType = 1 THEN UserID ELSE 0 END) AS RODID, 
		MAX(CASE WHEN Users.UserType = 2 THEN UserID ELSE 0 END) AS BDMID,
		MAX(CASE WHEN Users.UserType = 9 THEN UserID ELSE 0 END) AS CAMID 
		FROM UserSites
		JOIN Users ON Users.ID = UserSites.UserID 
		WHERE Users.UserType IN (1,2,9)
		GROUP BY UserSites.EDISID 
		) AS UsersTEMP
--------------------------------------------------------------------------------------------------
	JOIN Users AS RODUsers ON RODUsers.ID = UsersTEMP.RODID
	JOIN Users AS BDMUsers ON BDMUsers.ID = UsersTEMP.BDMID 
	JOIN Users AS CAMUsers ON CAMUsers.ID = UsersTEMP.CAMID
	RIGHT JOIN Sites ON Sites.EDISID = UsersTEMP.EDISID 
	JOIN Areas ON Sites.AreaID = Areas.ID 

	) AS MYUsers ON MYUsers.EDISID = Sites.EDISID

  Where WeekCommencing BETWEEN  @StartDate AND @EndDate

  And Hidden=0 and Products.Description NOT IN ( 'Not In Use Line','Not In Use Cask Line')

  Group BY  
	MYUsers.RODName
	,MYUsers.BDMName
	,MYUsers.CAMName
	,PCTDW.EDISID
	,SiteID
	,Sites.Name
	,Sites.PostCode
	,ProductCategories.Description
	,Products.Description
	,[Pump]
	,[ProductID]