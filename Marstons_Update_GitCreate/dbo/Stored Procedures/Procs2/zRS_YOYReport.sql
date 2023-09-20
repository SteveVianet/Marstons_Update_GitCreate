CREATE PROCEDURE [dbo].[zRS_YOYReport]
AS

SET NOCOUNT ON

SELECT      RODName
                  , BDMName
                  , SiteID
            ,Name
            ,SiteLevel.[LY Period]  AS  [LY Period]
            ,SiteLevel.[TY Period]  AS  [TY Period]   
            ,(SiteLevel.PeriodYear+PeriodNumber)                  AS [PeriodCode]         
            ,SUM([DEL LY])                AS    [DEL LY]
            ,SUM([DEL TY])                AS    [DEL TY]
            ,SUM([DIS LY])                AS    [DIS LY]
            ,SUM([DIS TY])                AS    [DIS TY]

FROM
(
            SELECT     ZUSERS.RODName
                                    , ZUSERS.BDMName
                                    , Sites.SiteID
                        ,Sites.Name
                        ,PeriodYear
                        ,PeriodNumber
                        ,Reds.Period                  AS  [TY Period]
                        ,PeriodYearLastYear
                        ,Reds2.Period                 AS  [LY Period]
                        ,Reds2.PeriodDelivered  AS    [DEL LY]
                        ,Reds.PeriodDelivered   AS    [DEL TY]
                        ,Reds2.PeriodDispensed  AS    [DIS LY]          
                        ,Reds.PeriodDispensed   AS    [DIS TY]

            FROM Reds

           JOIN Sites              ON Reds.EDISID          =     Sites.EDISID

                  JOIN 
                  (
                  SELECT  Sites.EDISID
                              ,SiteID
                              ,Name
                              ,Address1
                              ,PostCode
                              ,RODUsers.UserName AS RODName
                              ,BDMUsers.UserName AS BDMName
                              ,CAMUsers.UserName AS CAMName
                                                      
                                          
                  FROM (
                                    SELECT  UserSites.EDISID,
                                               MAX(CASE WHEN Users.UserType = 1    THEN UserID ELSE 0 END) AS RODID,
                                                MAX(CASE WHEN Users.UserType = 2    THEN UserID ELSE 0 END) AS BDMID,
                                                MAX(CASE WHEN Users.UserType = 9    THEN UserID ELSE 0 END) AS CAMID
                                                
                                    FROM UserSites
                                    
                                    JOIN Users ON Users.ID = UserSites.UserID
                                    WHERE Users.UserType IN (1,2,9)
                                    
                                    GROUP BY UserSites.EDISID
                                    
                              ) AS UsersTEMP

                              JOIN        Users AS RODUsers ON RODUsers.ID    = UsersTEMP.RODID
                              JOIN        Users AS BDMUsers ON BDMUsers.ID    = UsersTEMP.BDMID
                              JOIN        Users AS CAMUsers ON CAMUsers.ID    = UsersTEMP.CAMID
                              RIGHT JOIN  Sites                   ON Sites.EDISID   = UsersTEMP.EDISID

                  ) AS ZUSERS ON Sites.EDISID = ZUSERS.EDISID



            JOIN Reds AS Reds2      ON    Reds.EDISID       =     Reds2.EDISID
                  
            JOIN PubcoCalendars     ON    Reds.Period       =     PubcoCalendars.Period
                                          AND   Reds2.Period      =      PubcoCalendars.PeriodLY

            WHERE 
                  Reds.Period >= '0910PD01'

            AND Hidden = 0
            
            AND RODName IS NOT NULL
            
            AND Reds.InsufficientData = 0 AND Reds2.InsufficientData = 0

) AS SiteLevel

GROUP BY     
                  RODName
                  ,BDMName
                  ,SiteID
            , Name
            , SiteLevel.[TY Period] 
            , SiteLevel.[LY Period]
            , SiteLevel.PeriodYear
            , PeriodYearLastYear
            , PeriodNumber


ORDER BY      SiteID
            , SiteLevel.[TY Period]

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[zRS_YOYReport] TO PUBLIC
    AS [dbo];

