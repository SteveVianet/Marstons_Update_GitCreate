---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE IsUserMemberOfRole
(
	@User	VARCHAR(255),
	@Role	VARCHAR(255)
)

AS

DECLARE @Count	INTEGER

SELECT @Count = COUNT(Users.name)
FROM sysusers AS Users
JOIN sysmembers AS Members ON Users.uid = Members.memberuid
JOIN sysusers AS Groups ON Groups.uid = Members.groupuid
WHERE Groups.name = @Role
AND Groups.issqlrole = 1
AND Users.[name] = @User

RETURN @Count


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[IsUserMemberOfRole] TO PUBLIC
    AS [dbo];

