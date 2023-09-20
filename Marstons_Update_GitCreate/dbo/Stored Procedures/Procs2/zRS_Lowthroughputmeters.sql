CREATE PROCEDURE [dbo].[zRS_Lowthroughputmeters]

(     @StartDate DATETIME = NULL,
 @EndDate DATETIME = NULL
)

AS

SET NOCOUNT ON

--to identify the low throughput meters in a customers estate using parameter set in owners table
--which is set via the set up page on the idraught website
--the values are compared to the thresholds on the website to set an RAG traffic light





SELECT 
Sites.SiteID
,MYUsers.BDMName
,MYUsers.RODName
, SUM( Counttaps.Lowthroughtputmeter) AS '#Taps'

, CASE WHEN  SUM(Counttaps.Lowthroughtputmeter)>=[ThroughputRedTaps] THEN 'Red'
WHEN   SUM( Counttaps.Lowthroughtputmeter)>=[ThroughputAmberTaps] THEN 'Amber'
WHEN SUM( Counttaps.Lowthroughtputmeter) <[ThroughputAmberTaps] THEN 'Green'
ELSE 'Grey' END AS 'LTTrafficlight'
,O.ThroughputLowValue  AS 'LTV'


FROM [dbo].[Sites] as Sites



INNER  JOIN

(
 SELECT  Sites.EDISID
 ,Regions.Description AS Regn
 ,Areas.Description AS Area
 ,RODUsers.UserName AS RODName
 ,BDMUsers.UserName AS BDMName

 FROM 
 (
 SELECT UserSites.EDISID
  ,MAX(CASE WHEN Users.UserType = 1 THEN UserID ELSE 0 END) AS RODID
 ,MAX(CASE WHEN Users.UserType = 2 THEN UserID ELSE 0 END) AS BDMID

 FROM UserSites
 
 JOIN Users ON Users.ID = UserSites.UserID
 WHERE Users.UserType IN (1,2)
 
 GROUP BY UserSites.EDISID
 
  ) AS UsersTEMP

 JOIN Users AS RODUsers ON RODUsers.ID = UsersTEMP.RODID
 JOIN Users AS BDMUsers ON BDMUsers.ID = UsersTEMP.BDMID
 RIGHT JOIN Sites ON Sites.EDISID = UsersTEMP.EDISID
 Join Regions ON Sites.Region = Regions.ID
 JOIN Areas ON Sites.AreaID = Areas.ID


 ) AS MYUsers ON MYUsers.EDISID = Sites.EDISID


INNER JOIN 

(SELECT Sites.SiteID,PCTDW.EDISID,
      --[WeekCommencing]
      Products.Description AS 'Productdescr'
      ,ProductCategories.Description AS 'Categorydescr'
      ,[Pump]
      ,[ProductID]
      ,AVG ([Volume] ) As AverageVolume
      ,COUNT ([Volume] ) As Weeks
         ,SUM (Volume) AS Total
         , CASE WHEN AVG ([Volume] ) <= Owners.ThroughputLowValue    
              THEN 1 ELSE 0 END AS 'Lowthroughtputmeter'
 
  FROM [dbo].[PeriodCacheTradingDispenseWeekly] AS PCTDW



  JOIN Sites ON Sites.EDISID = PCTDW.EDISID
  JOIN Products ON Products.ID = PCTDW.ProductID
  JOIN ProductCategories ON Products.CategoryID = ProductCategories.ID
  JOIN Owners ON Sites.OwnerID = Owners.ID

  Where WeekCommencing BETWEEN  @StartDate AND @EndDate
 
 ---and SiteID IN ('897428','202857','897311')

  And Hidden=0 and Products.Description NOT IN ( 'Not In Use Line','Not In Use Cask Line')

  Group BY  PCTDW.EDISID,SiteID,ProductCategories.Description,Products.Description
      ,[Pump]
      ,[ProductID]
         ,Owners.ThroughputLowValue ) AS Counttaps 
  ON Sites.EDISID = Counttaps.EDISID

 LEFT JOIN Owners AS O ON Sites.OwnerID =  O.ID


  Group BY Sites.SiteID,[MYUsers].RODName,MYUsers.BDMName,[ThroughputRedTaps],[ThroughputAmberTaps],O.ThroughputLowValue

  Order BY #Taps DESC
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[zRS_Lowthroughputmeters] TO PUBLIC
    AS [dbo];

