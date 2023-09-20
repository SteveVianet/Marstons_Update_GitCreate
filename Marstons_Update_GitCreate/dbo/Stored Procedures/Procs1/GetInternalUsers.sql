CREATE PROCEDURE [dbo].[GetInternalUsers]

AS
BEGIN

	SELECT 
		ID, UserName
	FROM 
		dbo.InternalUsers
END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetInternalUsers] TO PUBLIC
    AS [dbo];

