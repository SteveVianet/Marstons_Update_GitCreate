---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE GetBudgets
(
	@EDISID	INTEGER
)

AS

SELECT WeekNo, Quantity 
FROM dbo.Budgets
WHERE EDISID = @EDISID


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetBudgets] TO PUBLIC
    AS [dbo];

