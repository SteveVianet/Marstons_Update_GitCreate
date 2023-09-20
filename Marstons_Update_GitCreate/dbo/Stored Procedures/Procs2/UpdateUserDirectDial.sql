CREATE PROCEDURE [dbo].[UpdateUserDirectDial] 
(
	@Username	VARCHAR(50),
	@DirectDial	VARCHAR(25)
)
AS

EXEC [SQL1\SQL1].ServiceLogger.dbo.UpdateUserDirectDial @Username, @DirectDial

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateUserDirectDial] TO PUBLIC
    AS [dbo];

