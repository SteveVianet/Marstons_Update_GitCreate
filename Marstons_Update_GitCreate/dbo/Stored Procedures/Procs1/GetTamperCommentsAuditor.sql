
CREATE PROCEDURE [dbo].[GetTamperCommentsAuditor]
	@EDISID	INTEGER,
	@FromDate	DATETIME = NULL,
	@ToDate	DATETIME = NULL
AS
BEGIN
	
	SET NOCOUNT ON;

    SELECT
	tce.CaseID AS [CaseID],
	tce.EventDate AS [Date], 
	ISNULL(REPLACE(SUBSTRING(iu.UserName,CHARINDEX('\',iu.UserName)+1,LEN(iu.UserName)), '.', ' '),'') As RaisedBy,
	tce.UserID As RaisedByID,
	tce.SeverityID AS [SeverityID],
	tced.[Description] AS [SeverityDescription],
	ISNULL(tce.SeverityUserID, 1) AS [SeverityUserID],
	tce.StateID AS [StateID],
	
	CASE 
		WHEN tce.StateID = 1 THEN 'Raise'
		WHEN tce.StateID = 2 THEN 'Accepted'
		WHEN tce.StateID = 3 THEN 'Rejected'
		WHEN tce.StateID = 4 THEN 'Edited'
		WHEN tce.StateID = 5 THEN 'Update'
		WHEN tce.StateID = 6 THEN 'Close'
	END AS [Status], 

	tce.TypeListID AS [TypeListID],
	tce.[Text] AS [Text],
	
	ISNULL(REPLACE(SUBSTRING(tce.AcceptedBy,CHARINDEX('\',tce.AcceptedBy)+1,LEN(tce.AcceptedBy)), '.', ' '),'') As AcceptedBy,
	MethodOfTampering.[Description] AS Method

FROM
	TamperCases AS tc
		INNER JOIN TamperCaseEvents AS tce ON tce.CaseID = tc.CaseID
		INNER JOIN InternalUsers AS iu ON iu.ID = tce.UserID
		INNER JOIN TamperCaseEventsSeverityDescriptions AS tced ON tced.ID = tce.SeverityID
		INNER JOIN (SELECT B.RefID,
						(SELECT C.[Description]
						 FROM TamperCaseEventTypeList AS A
							INNER JOIN TamperCaseEventTypeDescriptions AS C ON C.ID = A.TypeID
						 WHERE A.RefID = B.RefID) as [Description]
						 
					FROM TamperCaseEventTypeList AS B) AS MethodOfTampering ON MethodOfTampering.RefID = tce.TypeListID
WHERE
	tc.EDISID=@EDISID					
		AND
	
	(	@FromDate IS NULL 						OR 
		@ToDate IS NULL 						OR
		EventDate BETWEEN @FromDate AND @ToDate	)
ORDER BY 
	EventDate DESC
END

GRANT EXEC ON [dbo].GetTamperCommentsAuditor TO [public]


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetTamperCommentsAuditor] TO PUBLIC
    AS [dbo];

