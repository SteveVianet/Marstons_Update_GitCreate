CREATE PROCEDURE [dbo].[zRS_WeeklyDispenseVolume]

AS

SET DATEFIRST 1

DECLARE @TodayDayOfWeek INT
DECLARE @EndOfPrevWeek DateTime
DECLARE @StartOfPrevWeek DateTime

--get number of a current day (1-Monday, 2-Tuesday... 7-Sunday)
SET @TodayDayOfWeek = datepart(dw, GetDate())

--get the last day of the previous week (last Sunday)
SET @EndOfPrevWeek = DATEADD(dd, -@TodayDayOfWeek, CAST(GetDate() AS DATE))

--get the first day of the previous week (the Monday before last)
SET @StartOfPrevWeek = DATEADD(dd, -(@TodayDayOfWeek+6), CAST(GETDATE() AS DATE))

--Now we can use above expressions in our query:
Print @TodayDayOfWeek
Print @StartOfPrevWeek 
Print @EndOfPrevWeek


SELECT   
            DB_NAME()                                                   AS Customer
            , PeriodCacheTradingDispense.EDISID
            , PeriodCacheTradingDispense.TradingDay
            , (PeriodCacheTradingDispense.Volume)+(PeriodCacheTradingDispense.WastedVolume)            AS Pints
            , Products.Description                                AS Product
            , ProductCategories.Description                       AS Category
            , Sites.SiteID
            , Sites.Name
            , Sites.Address1
            , Sites.Address2
            , Sites.Address3
            , Sites.Address4
            , Sites.PostCode
            , ODUsers.UserName                                          AS OD
            , BDMUsers.UserName                                         AS BDM
            , Owners.Name AS Owners

FROM     Sites 

JOIN     PeriodCacheTradingDispense ON Sites.EDISID               = PeriodCacheTradingDispense.EDISID 

JOIN
(
            SELECT      UserSites.EDISID
                       ,MAX(CASE WHEN Users.UserType = 1   THEN UserID ELSE 0 END) AS ODID
                        ,MAX(CASE WHEN Users.UserType = 2   THEN UserID ELSE 0 END) AS BDMID
                        
            FROM UserSites
            
            JOIN Users ON Users.ID = UserSites.UserID
            WHERE Users.UserType IN (1,2)
            
            GROUP BY UserSites.EDISID
      
)    AS UsersTEMP ON UsersTEMP.EDISID = Sites.EDISID

JOIN  Users AS ODUsers  ON ODUsers.ID     = UsersTEMP.ODID
JOIN  Users AS BDMUsers ON BDMUsers.ID    = UsersTEMP.BDMID

JOIN     Products                         ON PeriodCacheTradingDispense.ProductID = Products.ID
JOIN     ProductCategories                ON Products.CategoryID  = ProductCategories.ID 
 
JOIN     Owners                                 ON Sites.OwnerID        = Owners.ID

WHERE     
      PeriodCacheTradingDispense.TradingDay BETWEEN @StartOfPrevWeek AND @EndOfPrevWeek

        AND ProductCategories.Description <>'Syrup'
        AND Sites.Status IN (1,2,3)
		AND Sites.Hidden = 0
		AND Sites.SiteID NOT LIKE 'HL%'

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[zRS_WeeklyDispenseVolume] TO PUBLIC
    AS [dbo];

