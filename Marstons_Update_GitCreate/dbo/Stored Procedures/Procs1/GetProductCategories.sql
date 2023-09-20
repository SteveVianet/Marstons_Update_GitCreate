CREATE PROCEDURE [dbo].[GetProductCategories]

AS

SELECT	[ID],
	[Description],
	[MinimumPouringYield],
	[MaximumPouringYield],
	[LowPouringYieldErrThreshold],
	[HighPouringYieldErrThreshold]
FROM ProductCategories
ORDER BY UPPER([Description])

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetProductCategories] TO PUBLIC
    AS [dbo];

