---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE GetUserLevel

AS

DECLARE @User 	VARCHAR(255)
DECLARE @UserLevel	INTEGER
SET @User = SUSER_SNAME()

EXEC @UserLevel = [SQL1\SQL1].ServiceLogger.dbo.GetUserLevel @User

SELECT @UserLevel AS UserLevel



GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetUserLevel] TO PUBLIC
    AS [dbo];

