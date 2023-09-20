CREATE Procedure [dbo].[zRS_GetOutstandingVRSActions]
AS
Select      
			Configuration.PropertyValue														AS Company

			,RODUsers.UserName                                           AS ROD
            ,BDMUsers.UserName                                                AS BDM
            ,CAMUsers.UserName                                                AS CAM
            ,SiteID
            ,Name
            ,VisitDate                                                        AS    [Visit Date]
            ,VRSVisitOutcome.Description                          AS    [Visit Outcome]
            ,SUM(VisitDamages.Damages)                                  AS    [Suggested Damages]
            ,DATEDIFF(DAY,VisitDate,GetDate())                    AS    [Days Old]
      
FROM VisitRecords

JOIN  Configuration				ON Configuration.PropertyName = 'Company Name' 

JOIN  Sites						ON    Sites.EDISID            =     VisitRecords.EDISID        
LEFT JOIN (
      SELECT  UserSites.EDISID,
                 MAX(CASE WHEN Users.UserType = 1    THEN UserID ELSE 0 END) AS RODID,
                  MAX(CASE WHEN Users.UserType = 2    THEN UserID ELSE 0 END) AS BDMID,
                  MAX(CASE WHEN Users.UserType = 9    THEN UserID ELSE 0 END) AS CAMID
                  
      FROM UserSites
      
      JOIN Users ON Users.ID = UserSites.UserID
      WHERE Users.UserType IN (1,2,9)
      
      GROUP BY UserSites.EDISID
      
      ) AS UsersTEMP ON UsersTEMP.EDISID = Sites.EDISID    
            



LEFT JOIN  Users AS RODUsers ON    RODUsers.ID             =     UsersTEMP.RODID
LEFT JOIN  Users AS BDMUsers ON    BDMUsers.ID             =     UsersTEMP.BDMID
LEFT JOIN  Users AS CAMUsers ON    CAMUsers.ID             =     UsersTEMP.CAMID

JOIN  [SQL1\SQL1].ServiceLogger.dbo.VRSVisitOutcome AS VRSVisitOutcome ON VRSVisitOutcome.ID = VisitRecords.VisitOutcomeID
JOIN  VisitDamages            ON    VisitDamages.VisitRecordID    =     VisitRecords.ID


WHERE FurtherActionID IN (2,3)

AND VisitDate >= '2012-01-01'

AND CompletedByCustomer IS NULL

AND VisitRecords.Deleted = 0

AND Sites.Hidden = 0

AND Sites.SiteID NOT LIKE 'HL%'

Group BY
			Configuration.PropertyValue
			,RODUsers.UserName                                     
            ,BDMUsers.UserName                                    
            ,CAMUsers.UserName                                          
            ,SiteID
            ,Name
            ,VisitDate
            ,VRSVisitOutcome.Description


ORDER BY ROD,BDM, [Days Old] Desc

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[zRS_GetOutstandingVRSActions] TO PUBLIC
    AS [dbo];

