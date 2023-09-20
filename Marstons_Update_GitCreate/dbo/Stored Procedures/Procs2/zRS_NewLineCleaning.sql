CREATE PROCEDURE [dbo].[zRS_NewLineCleaning]


(
@From DATETIME=NULL,
@To DATETIME= NULL)

AS SET NOCOUNT ON

/* SBain (03/April/2020): Send email on execution to notify if SP is still in use */
DECLARE @Body NVARCHAR(MAX) = 'Stored Procedure ''' + STUFF((SELECT ' ' + OBJECT_NAME(@@PROCID)),1,1,'') + ''' executed for ''' + STUFF((SELECT ' ' + DB_NAME()),1,1,'') + ''' (Steve Bain is a Legend).';
EXEC SendEmail  'Software.Engineers@vianetplc.com', 'SoftwareEngineers', 'Software.Engineers@vianetplc.com', 'Old Line Cleaning SP Executed', @Body;
/* END OF CHANGE */

SELECT  RODName AS OM
,BDMName AS BRM
,Sites.SiteID
,Sites.Name
,Sites.Address1
,Sites.Address2
,Sites.Address3
,Sites.Address4
,PostCode
,Owners.CleaningAmberPercentTarget
,Owners.CleaningRedPercentTarget
,SUM(TotalDispense) AS TotalDispense
,SUM(CleanDispense) AS CleanDispense
,SUM(DueCleanDispense) AS DueCleanDispense
,SUM(OverdueCleanDispense) AS OverdueCleanDispense

 ,CASE WHEN SUM(TotalDispense) = 0 THEN 0
  ELSE (SUM(OverdueCleanDispense) / SUM(TotalDispense))*100 END AS PercentServedUnclean
  
 ,CASE WHEN SUM(TotalDispense) = 0 THEN 'No Trade'
  WHEN (SUM(OverdueCleanDispense) / SUM(TotalDispense))*100 > Owners.CleaningRedPercentTarget THEN 'Red'
  WHEN (SUM(OverdueCleanDispense) / SUM(TotalDispense))*100 > Owners.CleaningAmberPercentTarget THEN 'Amber'
  ELSE 'Green' 
  END AS TrafficLight
,Quality

FROM PeriodCacheCleaningDispense

JOIN Sites ON Sites.EDISID = PeriodCacheCleaningDispense.EDISID

JOIN Owners ON Owners.ID = Sites.OwnerID

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
Join Regions ON Sites.Region = Regions.ID
JOIN Areas ON Sites.AreaID = Areas.ID


) AS MYUsers ON MYUsers.EDISID = PeriodCacheCleaningDispense.EDISID


WHERE [Date] BETWEEN @From AND @To


AND CategoryID NOT IN (18,24,27,30)
  AND Hidden = 0
  --AND Sites.SiteID NOT LIKE 'HL%'

GROUP BY RODName
,BDMName
,Sites.SiteID
,Sites.Name
,Sites.Address1
,Sites.Address2
,Sites.Address3
,Sites.Address4
,PostCode
,Quality
,Owners.CleaningRedPercentTarget
,Owners.CleaningAmberPercentTarget

ORDER BY RODName, BDMName, SiteID
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[zRS_NewLineCleaning] TO PUBLIC
    AS [dbo];

