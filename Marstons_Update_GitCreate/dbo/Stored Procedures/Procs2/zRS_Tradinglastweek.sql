CREATE PROCEDURE [dbo].[zRS_Tradinglastweek]

(
 @lowtradevalue INT =0,
@From DATETIME =NULL,
@To DATETIME =NULL
)

AS 

SET NOCOUNT ON


SELECT Sites.EDISID
      ,[OwnerID]
      ,[SiteID]
  , SiteGroupSites.IsPrimary
  ,SiteGroupSites.SiteGroupID
      ,[Name]      
      ,[Address3]
      ,[PostCode]    
   ,LastDownload   
   ,MYUsers.BDMName
   ,MYUsers.RODName
   ,Countlowdays.LowDays
         ,Calendar.CalendarDate
         ,SUM(Dispense.Volume) AS Volume
         ,CASE WHEN (SUM(Dispense.Volume)<= @lowtradevalue AND SUM(Dispense.Volume)>0 ) THEN 1 ELSE 0  END AS Lowtradeday
         ,CASE WHEN (SUM(Dispense.Volume) IS NULL) THEN 1 ELSE 0 END AS Notrade,
  SiteGroupTypes.Description

  , CASE dbo.Sites.Status WHEN 1 THEN 'Installed - Active' WHEN 2 THEN 'Installed - Closed' WHEN 10 THEN 'Installed - FOT' WHEN 3 THEN 'Installed - Legals'
 WHEN 4 THEN 'Installed - Not Reported On
' WHEN 5 THEN 'Installed - Written Off' WHEN 7 THEN 'Not Installed - Missing/Not Uplifted By Brulines
' WHEN 9 THEN 'Not Installed - Non Brulines
' WHEN 8 THEN 'Not Installed System To Be Refit
' WHEN 6 THEN 'Not Installed - Uplifted'
  WHEN 11 THEN 'TelecomsActive'
  WHEN 0 THEN 'Unknown' END AS Sitestatus

 --COUNT(Lowdaysdispense.EDISID) AS CountDispenseDays

  FROM [Sites]


CROSS JOIN Calendar
LEFT JOIN 
(
       SELECT EDISID, TradingDay, SUM(Volume) AS Volume
       FROM PeriodCacheTradingDispense
       WHERE TradingDay BETWEEN @From AND @To
       GROUP BY EDISID, TradingDay
) AS Dispense ON Dispense.EDISID = Sites.EDISID AND Dispense.TradingDay = Calendar.CalendarDate


LEFT JOIN 
(
SELECT EDISID, DATEDIFF(DAY, @From, @To) + 1 - SUM(CASE WHEN Volume > @lowtradevalue THEN 1 ELSE 0 END) AS LowDays
FROM(
 SELECT EDISID, SUM(Volume) AS Volume --CASE WHEN SUM(Volume) > @lowtradevalue THEN 1 ELSE 0 END AS CountOfHighDays
       FROM PeriodCacheTradingDispense
       WHERE TradingDay BETWEEN @From AND @To
    GROUP BY EDISID, TradingDay
    --HAVING SUM(Volume) > @lowtradevalue
    --ORDER BY EDISID
) AS DailyData

GROUP BY EDISID
) AS Countlowdays ON Countlowdays.EDISID =Sites.EDISID




JOIN
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
 JOIN Regions ON Sites.Region = Regions.ID
 JOIN Areas ON Sites.AreaID = Areas.ID

 ) AS MYUsers ON MYUsers.EDISID = Sites.EDISID

 --INNER JOIN 
FULL OUTER JOIN SiteGroupSites AS SiteGroupSites ON SiteGroupSites.EDISID = Sites.EDISID
FULL OUTER JOIN SiteGroups AS SiteGroups ON SiteGroups.ID =SiteGroupSites.SiteGroupID
FULL OUTER JOIN SiteGroupTypes AS SiteGroupTypes ON SiteGroupTypes.ID =SiteGroupSites.SiteGroupID


  Where 

  Hidden=0
  AND (CalendarDate BETWEEN @From AND @To)
  AND ((IsPrimary <> 0) OR (IsPrimary IS NULL))
  AND Sites.SiteID NOT LIKE 'HL%'

  Group BY OwnerID,Sites.EDISID,SiteGroupSites.IsPrimary,SiteGroupSites.SiteGroupID,Calendar.CalendarDate,Countlowdays.LowDays,SiteID,Name,Address3,PostCode,Status, MYUsers.BDMName
   ,MYUsers.RODName,LastDownload ,SiteGroupTypes.Description
   ORDER BY Sites.EDISID, CalendarDate




GO
GRANT EXECUTE
    ON OBJECT::[dbo].[zRS_Tradinglastweek] TO PUBLIC
    AS [dbo];

