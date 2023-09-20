CREATE PROCEDURE [dbo].[AddAlias]
(
	@ProductID	INTEGER,
	@Alias		VARCHAR(50),
	@VolumeMultiplier FLOAT = 1,
	@CreatedBy VARCHAR(50) = null,
	@CreatedOn DATETIME = null
)

AS

INSERT INTO dbo.ProductAlias
(ProductID, Alias, VolumeMultiplier, CreatedBy, CreatedOn)
VALUES
(@ProductID, UPPER(@Alias), @VolumeMultiplier, @CreatedBy, @CreatedOn)

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddAlias] TO PUBLIC
    AS [dbo];

