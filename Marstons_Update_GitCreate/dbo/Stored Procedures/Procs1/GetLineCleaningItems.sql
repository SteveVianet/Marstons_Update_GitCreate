CREATE PROCEDURE dbo.GetLineCleaningItems

	@User varChar(255) = null
AS

SELECT LineCleaning.EDISID,
	[Date], 
	CAST(CASE Implied WHEN 0 THEN 0 ELSE 1 END AS BIT) AS Implied,
	Viewed,
	Sites.SiteID
FROM dbo.LineCleaning WITH (NOLOCK)
JOIN Sites WITH (NOLOCK) ON Sites.EDISID = LineCleaning.EDISID
WHERE Processed = 0
AND ((UPPER(SiteUser) = UPPER(@User)) OR (@User IS null And UPPER(SiteUser) = UPPER(SYSTEM_USER))
OR SiteUser = '')
ORDER BY Sites.SiteID, [Date]

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetLineCleaningItems] TO PUBLIC
    AS [dbo];

