CREATE PROCEDURE [dbo].[GetRejectedTamperCases]
(
	@FromDate	DATETIME,
	@ToDate	DATETIME
)
AS

SELECT
	EDISID
FROM
	TamperCaseEvents
JOIN
	TamperCases
ON
	TamperCases.CaseID = TamperCaseEvents.CaseID
WHERE
	TamperCaseEvents.StateID=2 AND
	EventDate BETWEEN @FromDate AND @ToDate
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetRejectedTamperCases] TO PUBLIC
    AS [dbo];

