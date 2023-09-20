CREATE PROCEDURE AddGlobalLocation
(
	@Location	VARCHAR(50),
	@GlobalID	INTEGER = 0,
	@ID		INT OUTPUT
)

AS

--EXEC [SQL2\SQL2].[Global].dbo.AddLocation @Location, @GlobalID, @ID OUTPUT


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddGlobalLocation] TO PUBLIC
    AS [dbo];

