---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE GetSiteActionSummary
(
	@From		DATETIME,
	@To		DATETIME
)

AS

SELECT 	UserName,
	ActionID,
	CAST(CONVERT(VARCHAR(10), [TimeStamp], 121) AS SMALLDATETIME) AS [Date],
	COUNT(*) AS ActionCount
FROM SiteActions
WHERE [TimeStamp] BETWEEN @From AND @To
GROUP BY UserName, ActionID, CAST(CONVERT(VARCHAR(10), [TimeStamp], 121) AS SMALLDATETIME)
ORDER BY UserName, ActionID, CAST(CONVERT(VARCHAR(10), [TimeStamp], 121) AS SMALLDATETIME)


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSiteActionSummary] TO [TeamLeader]
    AS [dbo];

