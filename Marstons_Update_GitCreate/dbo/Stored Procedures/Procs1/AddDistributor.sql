CREATE PROCEDURE [dbo].[AddDistributor]
(
	@ShortName VARCHAR(5),
	@Name VARCHAR(100),
	@NewID INTEGER OUTPUT
)

AS

INSERT INTO dbo.ProductDistributors
(ShortName, Description)
VALUES
(@ShortName, @Name)

SET @NewID = @@IDENTITY


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddDistributor] TO PUBLIC
    AS [dbo];

