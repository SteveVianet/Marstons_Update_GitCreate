
CREATE PROCEDURE [dbo].[GetInternalUserName]
(
	@UserID	INTEGER,
	@UserName	VARCHAR(60)	OUT
)
AS
BEGIN

	SELECT 
		@UserName = [UserName] 
	FROM 
		dbo.InternalUsers
	WHERE
		[ID] = @UserID

END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetInternalUserName] TO PUBLIC
    AS [dbo];

