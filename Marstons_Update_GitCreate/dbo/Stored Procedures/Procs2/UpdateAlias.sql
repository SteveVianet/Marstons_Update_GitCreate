CREATE PROCEDURE dbo.UpdateAlias 

	@Alias		VARCHAR(50),
	@VolumeMultiplier FLOAT = 1
AS
BEGIN

	SET NOCOUNT ON;
	
	UPDATE dbo.ProductAlias
	SET VolumeMultiplier = @VolumeMultiplier
	WHERE Alias = @Alias
	
END
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateAlias] TO PUBLIC
    AS [dbo];

