CREATE PROCEDURE [dbo].[GetWebUserVisitRecordsPendingCompletion]
(
	@UserID AS INT
)
AS

SET NOCOUNT ON

DECLARE @AllSites INT
DECLARE @DatabaseID INT

SELECT @AllSites = AllSitesVisible FROM UserTypes
JOIN Users ON UserType = UserTypes.ID
WHERE Users.ID = @UserID

DECLARE @DamagesStatus AS INT
SET @DamagesStatus = 0

SELECT @DatabaseID = CAST(PropertyValue AS INTEGER)
FROM dbo.Configuration
WHERE PropertyName = 'Service Owner ID'

CREATE TABLE #VRSReasonForVisit([ID] INT NOT NULL, [Description] VARCHAR(100) NOT NULL)
CREATE TABLE #VRSVisitOutcome([ID] INT NOT NULL, [Description] VARCHAR(100) NOT NULL)

INSERT INTO #VRSReasonForVisit
([ID], [Description])
EXEC [SQL1\SQL1].ServiceLogger.dbo.GetVRSReasonForVisit

INSERT INTO #VRSVisitOutcome
([ID], [Description])
EXEC [SQL1\SQL1].ServiceLogger.dbo.GetVRSVisitOutcome

SELECT	VisitRecords.[ID] AS VisitID,
		@DatabaseID AS DatabaseID,
		VisitRecords.EDISID,
		VisitDate,
		VRSReasonForVisit.[Description] AS Reason,
		VRSVisitOutcome.[Description] AS Outcome
FROM dbo.VisitRecords
JOIN Sites ON Sites.EDISID = VisitRecords.EDISID
LEFT JOIN #VRSReasonForVisit AS VRSReasonForVisit ON VRSReasonForVisit.[ID] = VisitRecords.VisitReasonID
LEFT JOIN #VRSVisitOutcome AS VRSVisitOutcome ON VRSVisitOutcome.[ID] = VisitRecords.VisitOutcomeID
WHERE ((CustomerID > 0 AND (FurtherActionID = 2 OR FurtherActionID = 3) AND (Actioned = 0))
	OR (CustomerID = 0 AND VerifiedByVRS = 1 AND (CompletedByCustomer = 0 OR CompletedByCustomer IS NULL)))
AND (@AllSites = 1 OR VisitRecords.EDISID IN (SELECT EDISID FROM UserSites WHERE UserID = @UserID))
--AND Quality = 1
AND IsVRSMember = 1
--AND Hidden = 0
AND VisitRecords.Deleted = 0

ORDER BY VisitDate, VisitTime

DROP TABLE #VRSReasonForVisit
DROP TABLE #VRSVisitOutcome
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetWebUserVisitRecordsPendingCompletion] TO PUBLIC
    AS [dbo];

