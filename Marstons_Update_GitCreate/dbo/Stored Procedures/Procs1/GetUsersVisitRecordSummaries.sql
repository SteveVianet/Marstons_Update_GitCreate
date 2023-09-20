CREATE PROCEDURE [dbo].[GetUsersVisitRecordSummaries]
(
	@UserID		INT
)

AS

SELECT	VisitRecords.[ID],
		Sites.EDISID,
		Sites.SiteID,
		Sites.[Name],
		Sites.PostCode,
		VisitRecords.EDISID,
		VisitRecords.FormSaved,
		VisitRecords.VisitDate,
		(CAST([ID] AS nvarchar) + ',' + CAST(Sites.EDISID AS nvarchar)) As NoteIndex,
		VisitRecords.ClosedByCAM,
		VisitRecords.DateSubmitted,
		VisitRecords.VerifiedByVRS,
		VisitRecords.CompletedByCustomer,
		COUNT(DamagesID) AS NumOfDamages,
		VisitRecords.CAMID

FROM dbo.Sites
JOIN VisitRecords ON VisitRecords.EDISID = Sites.EDISID
LEFT JOIN VisitDamages ON VisitRecordID = VisitRecords.[ID] AND DamagesType < 3
WHERE VisitRecords.CAMID = @UserID
AND (VisitRecords.CompletedByCustomer = 0 OR VisitRecords.CompletedByCustomer IS NULL)
AND (VisitRecords.VerifiedByVRS = 0 OR VisitRecords.VerifiedByVRS IS NULL)
AND (VisitRecords.CustomerID = 0)
AND (VisitRecords.Deleted = 0)

GROUP BY VisitRecords.[ID],
		Sites.EDISID,
		Sites.SiteID,
		Sites.[Name],
		Sites.PostCode,
		VisitRecords.EDISID,
		VisitRecords.FormSaved,
		VisitRecords.VisitDate,
		(CAST([ID] AS nvarchar) + ',' + CAST(Sites.EDISID AS nvarchar)),
		VisitRecords.ClosedByCAM,
		VisitRecords.DateSubmitted,
		VisitRecords.VerifiedByVRS,
		VisitRecords.CompletedByCustomer,
		VisitRecords.CAMID

ORDER BY ClosedByCAM, VerifiedByVRS, VisitDate

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetUsersVisitRecordSummaries] TO PUBLIC
    AS [dbo];

