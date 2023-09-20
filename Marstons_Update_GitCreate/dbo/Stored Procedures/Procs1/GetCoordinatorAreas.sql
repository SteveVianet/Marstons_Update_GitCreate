---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE GetCoordinatorAreas
(
	@AllCoordinators	BIT = 0
)

AS

IF @AllCoordinators = 1
BEGIN
	EXEC [SQL1\SQL1].ServiceLogger.dbo.GetCoordinatorAreas

END
ELSE
BEGIN
	DECLARE @User 	VARCHAR(255)
	SET @User = SUSER_SNAME()

	EXEC [SQL1\SQL1].ServiceLogger.dbo.GetCoordinatorAreas @User

END


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetCoordinatorAreas] TO PUBLIC
    AS [dbo];

