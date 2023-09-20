CREATE PROCEDURE GetCallLines
(
	@CallID INT
)

AS

SELECT	LineNumber,
	Location,
	VolumeDispensed,
	Product
FROM CallLines
WHERE CallID = @CallID


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetCallLines] TO PUBLIC
    AS [dbo];

