CREATE PROCEDURE [dbo].[GetUserDirectDial]
(
	@Username	VARCHAR(50)
)
AS

EXEC [SQL1\SQL1].ServiceLogger.dbo.GetUserDirectDial @Username

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetUserDirectDial] TO PUBLIC
    AS [dbo];

