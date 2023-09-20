CREATE PROCEDURE AddLocation
(
	@Location	VARCHAR(50),
	@GlobalID	INTEGER = 0,
	@ID		INT OUTPUT
)

AS

INSERT INTO dbo.Locations
([Description], GlobalID)
VALUES
(@Location, @GlobalID)

SET @ID = @@IDENTITY

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddLocation] TO PUBLIC
    AS [dbo];

