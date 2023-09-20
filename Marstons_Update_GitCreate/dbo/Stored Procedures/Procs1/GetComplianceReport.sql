CREATE PROCEDURE [dbo].[GetComplianceReport]
(
	@From					DATETIME,
	@CompletedByCustomer	BIT = NULL,
	@FurtherActionID		INT = NULL,
	@OMID					INT = NULL,
	@BDMID					INT = NULL,
	@CAMID					INT = NULL
)
AS

SET NOCOUNT ON

SELECT	VisitRecords.[ID],
		Areas.[Description] AS Region,
		BDMUsers.UserName AS BDM,
		CAMUsers.UserName AS CAM,
		Sites.SiteID,
		Sites.Name,
		Sites.PostCode,
		VisitRecords.VisitDate,
		VRSVisitOutcome.[Description] AS OverallOutcome,
		VRSSpecificOutcome.[Description] AS SpecificOutcome,
		VRSFurtherAction.[Description] AS ActionRecommended,
		VisitDamages.Damages AS EstimatedDamages,
		VisitRecords.DamagesObtainedValue AS UTLValue,
		VisitRecords.DamagesExplaination AS ReasonIfDifferent,
		VisitRecords.CompletedDate AS DateOfUpdate,
		VisitRecords.BDMDamagesIssuedValue AS BDMUTLValue,
		VisitRecords.BDMComment AS BDMVisitComments,
		VisitRecords.BDMPartialReason AS BDMReasonUTLLowerThanEstimates,
		dbo.fnGetWeekdayCount(VisitRecords.FormSaved, GETDATE()) AS DaysOutstanding,
		VRSActionTaken.[Description] AS BDMActionTaken
FROM VisitRecords
JOIN Sites ON Sites.EDISID = VisitRecords.EDISID
JOIN Users AS CAMUsers ON CAMUsers.[ID] = VisitRecords.CAMID
JOIN Areas ON Areas.[ID] = Sites.AreaID
JOIN [EDISSQL1\SQL1].ServiceLogger.dbo.VRSVisitOutcome AS VRSVisitOutcome ON VRSVisitOutcome.[ID] = VisitRecords.VisitOutcomeID
JOIN [EDISSQL1\SQL1].ServiceLogger.dbo.VRSSpecificOutcome AS VRSSpecificOutcome ON VRSSpecificOutcome.[ID] = VisitRecords.SpecificOutcomeID
JOIN [EDISSQL1\SQL1].ServiceLogger.dbo.VRSFurtherAction AS VRSFurtherAction ON VRSFurtherAction.[ID] = VisitRecords.FurtherActionID
LEFT JOIN [EDISSQL1\SQL1].ServiceLogger.dbo.VRSActionTaken AS VRSActionTaken ON VRSActionTaken.[ID] = VisitRecords.BDMActionTaken
LEFT JOIN (	SELECT VisitRecordID, SUM(Damages) AS Damages
			FROM VisitDamages
			GROUP BY VisitRecordID) AS VisitDamages ON VisitDamages.VisitRecordID = VisitRecords.[ID]
LEFT JOIN (	SELECT EDISID, MAX(UserID) AS BDMID
		FROM UserSites
		JOIN Users ON Users.[ID] = UserSites.UserID AND Users.UserType = 2
		GROUP BY EDISID ) AS SiteBDMUsers ON SiteBDMUsers.EDISID = Sites.EDISID
LEFT JOIN Users AS BDMUsers ON BDMUsers.[ID] = SiteBDMUsers.BDMID
LEFT JOIN (	SELECT EDISID, MAX(UserID) AS BDMID
		FROM UserSites
		JOIN Users ON Users.[ID] = UserSites.UserID AND Users.UserType = 1
		GROUP BY EDISID ) AS SiteOMUsers ON SiteOMUsers.EDISID = Sites.EDISID
LEFT JOIN Users AS OMUsers ON OMUsers.[ID] = SiteOMUsers.BDMID
LEFT JOIN (	SELECT EDISID, MAX([ID]) AS LastSiteVisitID
			FROM VisitRecords
			GROUP BY EDISID) AS LastSiteVisit ON LastSiteVisit.EDISID = VisitRecords.EDISID
WHERE (VisitRecords.FormSaved >= @From OR (VisitRecords.CompletedDate IS NULL AND VisitRecords.FurtherActionID = 2 AND @CompletedByCustomer = 0))
AND ((VisitRecords.CompletedDate IS NOT NULL AND VisitRecords.FurtherActionID = 2 AND @CompletedByCustomer = 1) OR (VisitRecords.CompletedDate IS NULL AND VisitRecords.FurtherActionID = 2 AND @CompletedByCustomer = 0) OR (@CompletedByCustomer IS NULL))
AND (VisitRecords.FurtherActionID = @FurtherActionID OR @FurtherActionID IS NULL)
AND ((VisitRecords.FurtherActionID IN (4, 5) AND VisitRecords.[ID] = LastSiteVisit.LastSiteVisitID) OR (VisitRecords.FurtherActionID = 2 OR @FurtherActionID IS NULL))
AND (OMUsers.[ID] = @OMID OR @OMID IS NULL)
AND (BDMUsers.[ID] = @BDMID OR @BDMID IS NULL)
AND (CAMUsers.[ID] = @CAMID OR @CAMID IS NULL)
ORDER BY VisitRecords.VisitDate

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetComplianceReport] TO PUBLIC
    AS [dbo];

