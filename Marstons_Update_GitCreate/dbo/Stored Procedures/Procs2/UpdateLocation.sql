CREATE PROCEDURE dbo.UpdateLocation
(
	@ID		INTEGER,
	@Description	VARCHAR(50),
	@GlobalID	INTEGER
)
AS

UPDATE dbo.Locations
SET [Description] = @Description, GlobalID = @GlobalID
WHERE [ID] = @ID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateLocation] TO PUBLIC
    AS [dbo];

