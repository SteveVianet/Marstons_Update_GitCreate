CREATE PROCEDURE GetLocations

AS

SELECT	[ID], 
		[Description],
		GlobalID
FROM dbo.Locations

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetLocations] TO PUBLIC
    AS [dbo];

