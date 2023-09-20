CREATE PROCEDURE [dbo].[UpdateDistributor]
(
	@DistributorID	INT,
	@ShortName VARCHAR (50),
	@Description VARCHAR(50)
)

AS

UPDATE dbo.ProductDistributors
SET ShortName = @ShortName, Description = @Description
WHERE ID = @DistributorID
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateDistributor] TO PUBLIC
    AS [dbo];

