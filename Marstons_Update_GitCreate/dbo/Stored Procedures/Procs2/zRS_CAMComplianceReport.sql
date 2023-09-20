CREATE PROCEDURE [dbo].[zRS_CAMComplianceReport]

AS

SET NOCOUNT ON

CREATE TABLE #SitesToExclude(EDISID INT)
CREATE TABLE #Sites(EDISID INT, SiteID VARCHAR(50), RMName VARCHAR(100), BDMName VARCHAR(100),CAMName VARCHAR(100))
CREATE TABLE #LastTwelvePeriods(PeriodNumber INT, Period VARCHAR(10))
CREATE TABLE #RedsData (RedsEDISID INT, RedsPeriod VARCHAR(50), InsufficientData BIT, CD FLOAT)

CREATE TABLE #VisitData (ID INT, VisitEDISID INT, CAM VARCHAR(100), FormSaved DATETIME, CustomerID INT, Customer  VARCHAR (150), Period2 VARCHAR(50),
 VisitDate DATE, VisitTime TIME, Admission VARCHAR (500),MadeBy VARCHAR(250), AdmissionReason VARCHAR(250),
 AdmissionFor VARCHAR(250), UTL BIT, SuggestedDams FLOAT, DamagesObtained BIT, DamagesValue FLOAT, VisitOutcomeID INT,
 VisitOutcome VARCHAR(250), SpecificOutcome VARCHAR(250), FurtherAction VARCHAR(250), BDMID INT, 
 BDMDate DATE, Actioned BIT, Injunction BIT, BDMUTL BIT, BDMDamages BIT, BDMDamagesValue FLOAT)


DECLARE @ExcludeFromRedsPropertyID INT
DECLARE @SQL VARCHAR(8000)
DECLARE @PeriodCount INT


SELECT @ExcludeFromRedsPropertyID = [ID]

FROM dbo.Properties

WHERE Name = 'Exclude From Reds'

INSERT INTO #SitesToExclude

 SELECT EDISID
 FROM dbo.SiteProperties
 WHERE PropertyID = @ExcludeFromRedsPropertyID

INSERT INTO #SitesToExclude

 SELECT EDISID
 FROM dbo.Sites
 WHERE EDISID IN 
 (
  SELECT EDISID
  FROM SiteGroupSites
  JOIN SiteGroups ON SiteGroups.ID = SiteGroupSites.SiteGroupID
  WHERE TypeID = 1 AND IsPrimary <> 1
 )


INSERT INTO #Sites

 (EDISID, SiteID)

 SELECT EDISID, SiteID
 FROM dbo.Sites
 WHERE Hidden = 0

UPDATE #Sites

SET    BDMName = BDMUser.UserName,

       RMName = RMUser.UserName,

    CAMName = CMUser.UserName

FROM (

       SELECT UserSites.EDISID,

             MAX(CASE WHEN UserType = 2 THEN UserID ELSE 0 END) AS BDMID,

              MAX(CASE WHEN UserType = 1 THEN UserID ELSE 0 END) AS RMID,

    MAX(CASE WHEN UserType = 9 THEN UserID ELSE 0 END) AS CMID

       FROM UserSites

       JOIN Users ON Users.ID = UserSites.UserID

       JOIN #Sites AS Sites ON UserSites.EDISID = Sites.EDISID

       WHERE UserType IN (1,2,9) AND UserSites.EDISID = Sites.EDISID

       GROUP BY UserSites.EDISID

) AS SiteManagers

JOIN #Sites AS Sites ON Sites.EDISID = SiteManagers.EDISID

JOIN Users AS BDMUser ON BDMUser.ID = SiteManagers.BDMID

JOIN Users AS RMUser ON RMUser.ID = SiteManagers.RMID

JOIN Users AS CMUser ON CMUser.ID = SiteManagers.CMID


SELECT @PeriodCount = COUNT(DISTINCT PeriodNumber) 
FROM PubcoCalendars

SET @SQL = 'INSERT INTO #LastTwelvePeriods
SELECT TOP ' + CAST(@PeriodCount AS VARCHAR) + ' PeriodNumber, Period
FROM dbo.PubcoCalendars
WHERE Processed = 1
ORDER BY ToWC DESC'

EXEC (@SQL)


INSERT INTO #RedsData

 SELECT EDISID
 ,Reds.Period
 ,InsufficientData
 ,CD

 FROM Reds

 JOIN #LastTwelvePeriods AS RollingYear ON RollingYear.Period = Reds.Period




INSERT INTO #VisitData

 SELECT 
 VisitRecords.ID
 ,VisitRecords.EDISID
 ,Users.UserName
 ,FormSaved
 ,CustomerID
 ,Configuration.PropertyValue  AS Customer
 ,PubcoCalendars.Period
 ,VisitDate
 ,CAST(VisitTime AS TIME) AS VisitTime
 ,VRSAdmission.Description AS Admission
 ,VRSAdmissionMadeBy.Description AS MadeBy
 ,VRSAdmissionReason.Description AS AdmissionReason
 ,VRSAdmissionFor.Description AS AdmissionFor
 ,UTLLOU
 ,SuggestedDamages.TotalSuggestedVolume AS NEWSuggested
 ,DamagesObtained
 ,DamagesObtainedValue
 ,VisitOutcomeID
 ,VRSVisitOutcome.Description AS VisitOutcome
 ,VRSSpecificOutcome.Description AS SpecificOutcome
 ,VRSFurtherAction.Description AS FurtherAction
 ,VisitRecords.BDMID
 ,BDMCommentDate
 ,Actioned
 ,Injunction
 ,BDMUTLLOU
 ,BDMDamagesIssued
 ,BDMDamagesIssuedValue
 
 FROM VisitRecords

 JOIN Configuration ON Configuration.PropertyName = 'Company Name'
 JOIN Users ON Users.ID = VisitRecords.CAMID
 JOIN Sites ON Sites.EDISID = VisitRecords.EDISID

 LEFT JOIN [SQL1\SQL1].ServiceLogger.dbo.VRSAccessDetails AS VRSAccessDetails ON VRSAccessDetails.ID = VisitRecords.AccessDetailsID
 LEFT JOIN [SQL1\SQL1].ServiceLogger.dbo.VRSActionTaken AS VRSActionTaken ON VRSActionTaken.ID = VisitRecords.BDMActionTaken
 LEFT JOIN [SQL1\SQL1].ServiceLogger.dbo.VRSAdmission AS VRSAdmission ON VRSAdmission.ID = VisitRecords.AdmissionID
 LEFT JOIN [SQL1\SQL1].ServiceLogger.dbo.VRSAdmissionFor AS VRSAdmissionFor ON VRSAdmissionFor.ID = VisitRecords.AdmissionForID
 LEFT JOIN [SQL1\SQL1].ServiceLogger.dbo.VRSAdmissionReason AS VRSAdmissionReason ON VRSAdmissionReason.ID = VisitRecords.AdmissionReasonID
 LEFT JOIN [SQL1\SQL1].ServiceLogger.dbo.VRSCompletedChecks AS VRSCompletedChecks ON VRSCompletedChecks.ID = VisitRecords.CompletedChecksID
 LEFT JOIN [SQL1\SQL1].ServiceLogger.dbo.VRSFurtherAction AS VRSFurtherAction ON VRSFurtherAction.ID = VisitRecords.FurtherActionID
 LEFT JOIN [SQL1\SQL1].ServiceLogger.dbo.VRSMetOnSite AS VRSMetOnSite ON VRSMetOnSite.ID = VisitRecords.MetOnSiteID
 LEFT JOIN [SQL1\SQL1].ServiceLogger.dbo.VRSReasonForVisit AS VRSReasonForVisit ON VRSReasonForVisit.ID = VisitRecords.VisitReasonID
 LEFT JOIN [SQL1\SQL1].ServiceLogger.dbo.VRSSpecificOutcome AS VRSSpecificOutcome ON VRSSpecificOutcome.ID = VisitRecords.SpecificOutcomeID
 LEFT JOIN [SQL1\SQL1].ServiceLogger.dbo.VRSTampering AS VRSTampering ON VRSTampering.ID = VisitRecords.TamperingID
 LEFT JOIN [SQL1\SQL1].ServiceLogger.dbo.VRSTamperingEvidence AS VRSTamperingEvidence ON VRSTamperingEvidence.ID = VisitRecords.TamperingEvidenceID
 LEFT JOIN [SQL1\SQL1].ServiceLogger.dbo.VRSVerification AS VRSVerification ON VRSVerification.ID = VisitRecords.VerificationID
 LEFT JOIN [SQL1\SQL1].ServiceLogger.dbo.VRSVisitOutcome AS VRSVisitOutcome ON VRSVisitOutcome.ID = VisitRecords.VisitOutcomeID

 LEFT JOIN [SQL1\SQL1].ServiceLogger.dbo.VRSMetOnSite AS VRSStockAgreed ON VRSStockAgreed.ID = VisitRecords.StockAgreedByID
 LEFT JOIN [SQL1\SQL1].ServiceLogger.dbo.VRSMetOnSite AS VRSAdmissionMadeBy ON VRSAdmissionMadeBy.ID = VisitRecords.AdmissionMadeByID



 LEFT JOIN (
 SELECT  VisitRecordID, 
 SUM(Damages) AS TotalSuggestedVolume
 FROM VisitDamages
 GROUP BY VisitRecordID
    ) AS SuggestedDamages ON SuggestedDamages.VisitRecordID = VisitRecords.ID


 LEFT JOIN
 (
 SELECT      UserSites.EDISID
 ,MAX(CASE WHEN Users.UserType = 1   THEN UserID ELSE 0 END) AS RMID
 ,MAX(CASE WHEN Users.UserType = 2   THEN UserID ELSE 0 END) AS BDMID
  ,MAX(CASE WHEN Users.UserType = 9  THEN UserID ELSE 0 END) AS CAMID
 
 FROM UserSites
 
 JOIN Users ON Users.ID = UserSites.UserID
 WHERE Users.UserType IN (1,2,9)
 
 GROUP BY UserSites.EDISID
 
 )   AS UsersTEMP ON UsersTEMP.EDISID = Sites.EDISID

 LEFT JOIN  Users AS RMUsers  ON RMUsers.ID     = UsersTEMP.RMID
 LEFT JOIN  Users AS BDMUsers ON BDMUsers.ID    = UsersTEMP.BDMID
 LEFT JOIN Users AS CAMUsers ON CAMUsers.ID    = UsersTEMP.CAMID

 JOIN PubcoCalendars ON CAST(VisitRecords.VisitDate AS DATE) BETWEEN  PubcoCalendars.FromWC AND DATEADD(DAY,6,PubcoCalendars.ToWC)

 WHERE

 YEAR(VisitRecords.VisitDate) >= YEAR(GetDate())-2





-- FINAL SELECT ---

SELECT *
FROM #LastTwelvePeriods AS RollingYear
JOIN #Sites AS Sites ON 1=1
LEFT JOIN #RedsData AS Reds ON Reds.RedsEDISID = Sites.EDISID AND Reds.RedsPeriod = RollingYear.Period

LEFT JOIN #VisitData AS Visits ON Visits.VisitEDISID = Sites.EDISID AND Visits.Period2 = RollingYear.Period

WHERE Sites.EDISID NOT IN (SELECT EDISID
 FROM #SitesToExclude)


Order BY Sites.EDISID, Reds.RedsPeriod

DROP TABLE #Sites
DROP TABLE #RedsData
DROP TABLE #LastTwelvePeriods
DROP TABLE #SitesToExclude
DROP TABLE #VisitData
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[zRS_CAMComplianceReport] TO PUBLIC
    AS [dbo];

