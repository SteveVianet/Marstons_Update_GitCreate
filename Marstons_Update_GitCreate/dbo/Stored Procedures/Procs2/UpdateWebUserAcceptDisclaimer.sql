CREATE PROCEDURE [dbo].[UpdateWebUserAcceptDisclaimer]  
(
	@UserID	INT

) AS

SET NOCOUNT ON

DECLARE @DatabaseID INT
SELECT @DatabaseID = CAST(PropertyValue AS INT)
FROM Configuration
WHERE PropertyName = 'Service Owner ID'


UPDATE Users
SET AcceptedDisclaimer = 1
WHERE ID = @UserID


EXEC [EDISSQL1\SQL1].ServiceLogger.dbo.UpdateWebUserAcceptDisclaimer @DatabaseID, @UserID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateWebUserAcceptDisclaimer] TO PUBLIC
    AS [dbo];

