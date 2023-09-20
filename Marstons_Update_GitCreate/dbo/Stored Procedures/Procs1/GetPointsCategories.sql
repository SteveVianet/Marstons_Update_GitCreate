---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE GetPointsCategories

AS

SELECT	[ID],
	[Description]
FROM PointsCategories
ORDER BY [Description]


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetPointsCategories] TO PUBLIC
    AS [dbo];

