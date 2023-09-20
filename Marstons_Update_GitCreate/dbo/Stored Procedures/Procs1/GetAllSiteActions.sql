---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE GetAllSiteActions
(
	@From		DATETIME,
	@To		DATETIME
)

AS

SELECT 	EDISID,
	UserName,
	[TimeStamp],
	ActionID
FROM SiteActions
WHERE [TimeStamp] BETWEEN @From AND @To
ORDER BY [TimeStamp], EDISID, ActionID


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetAllSiteActions] TO [TeamLeader]
    AS [dbo];

