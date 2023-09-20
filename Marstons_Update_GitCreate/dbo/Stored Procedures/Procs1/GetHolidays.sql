---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE GetHolidays

AS

SELECT [Date]
FROM Holidays
ORDER BY [Date]


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetHolidays] TO PUBLIC
    AS [dbo];

