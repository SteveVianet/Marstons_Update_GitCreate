CREATE PROCEDURE [dbo].[GetTamperCaseEvents] 
(
	@EDISID	INTEGER,
	@FromDate	DATETIME = NULL,
	@ToDate	DATETIME = NULL
)
AS

SELECT
	TamperCaseEvents.CaseID AS [CaseID],
	TamperCaseEvents.EventDate AS [Date], 
	InternalUsers.UserName AS [User],
	TamperCaseEvents.SeverityID AS [SeverityID],
	ISNULL(TamperCaseEvents.SeverityUserID, 1) AS [SeverityUserID],
	TamperCaseEvents.StateID AS [StateID],
	TamperCaseEvents.TypeListID AS [TypeListID],
	TamperCaseEvents.[Text] AS [Text],
	TamperCaseEvents.AttachmentsID AS [AttachmentsID],
	ISNULL(TamperCaseEvents.AcceptedBy, '') As AcceptedBy,
	dbo.udfConcatTamperCaseTypeIDs(TamperCaseEvents.CaseID, TamperCaseEvents.TypeListID) AS [Types]
FROM
	dbo.TamperCases,
	dbo.TamperCaseEvents,
	dbo.InternalUsers
WHERE
	dbo.TamperCases.EDISID=@EDISID					AND
	dbo.TamperCaseEvents.CaseID=dbo.TamperCases.CaseID		AND
	dbo.InternalUsers.[ID]=dbo.TamperCaseEvents.UserID			AND
	(	@FromDate IS NULL 						OR 
		@ToDate IS NULL 						OR
		EventDate BETWEEN @FromDate AND @ToDate	)
ORDER BY 
	EventDate DESC

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetTamperCaseEvents] TO PUBLIC
    AS [dbo];

