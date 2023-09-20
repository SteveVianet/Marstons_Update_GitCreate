CREATE PROCEDURE [dbo].[GetSiteVisitRecordSummaries]
(
	@EDISID	INT,
	@UserID	INT = NULL,
	@OnlyShowNotesForUsersSites BIT = 0,
	@OnlyShowNotesUserCreated BIT = 0
)

AS

SET NOCOUNT ON



SELECT	VisitRecords.[ID],
		VisitRecords.CustomerID,
		VisitRecords.EDISID,
		VisitRecords.VisitDate,
		Users.UserName,
		VisitRecords.ClosedByCAM,
		VisitRecords.DateSubmitted,
		VisitRecords.VerifiedByVRS,
		VisitRecords.VerifiedDate,
		VisitRecords.CompletedByCustomer,
		VisitRecords.CompletedDate,
		(CAST(VisitRecords.[ID] AS nvarchar) + ',' + CAST(VisitRecords.EDISID AS nvarchar)) As NoteIndex

FROM VisitRecords
JOIN Users ON VisitRecords.CAMID = Users.[ID]
JOIN Sites ON Sites.EDISID = VisitRecords.EDISID
JOIN UserTypes ON Users.UserType = UserTypes.[ID]
WHERE  VisitRecords.EDISID = @EDISID
AND (CAMID = @UserID OR @OnlyShowNotesUserCreated = 0 OR @UserID IS NULL)
AND (@UserID IS NULL OR UserTypes.AllSitesVisible = 1 OR @OnlyShowNotesForUsersSites = 0 OR @UserID IN (SELECT UserID FROM UserSites WHERE EDISID = VisitRecords.EDISID))
AND VisitRecords.Deleted = 0
ORDER BY CompletedByCustomer DESC, VisitDate DESC
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSiteVisitRecordSummaries] TO PUBLIC
    AS [dbo];

