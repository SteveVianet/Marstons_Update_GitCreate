CREATE PROCEDURE [dbo].[GetSiteActions]
(
	@EDISID		INT
)

AS

SELECT [User] AS UserName, 
		ValidFrom AS [Timestamp], 
		31 AS ActionID,
		StatusID
FROM SiteStatusHistory 
WHERE EDISID = @EDISID

UNION ALL

SELECT 	UserName,
	[TimeStamp],
	ActionID,
	0
FROM SiteActions
WHERE EDISID = @EDISID
ORDER BY ValidFrom
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSiteActions] TO PUBLIC
    AS [dbo];

