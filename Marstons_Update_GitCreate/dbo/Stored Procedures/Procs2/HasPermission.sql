---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE HasPermission
(
	@PermissionID	INT
)

AS

DECLARE @HasPermission	BIT
DECLARE @PermissionCount	INT

SELECT @HasPermission = SuperUser
FROM Logins
WHERE UPPER(Login) = UPPER(SUSER_SNAME())

IF @HasPermission = 1
	RETURN 1
ELSE
BEGIN
	SELECT @PermissionCount = COUNT(*)
	FROM Logins
	JOIN AllowedPermissions ON AllowedPermissions.LoginID = Logins.[ID]
	WHERE AllowedPermissions.PermissionID = @PermissionID
	AND UPPER(Logins.Login) = UPPER(SUSER_SNAME())

	IF @PermissionCount > 0
		RETURN 1

	ELSE
	BEGIN
		EXEC @HasPermission = [SQL1\SQL1].ServiceLogger.dbo.HasPermission @PermissionID
		RETURN @HasPermission

	END
END


