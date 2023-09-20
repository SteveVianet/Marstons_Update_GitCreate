CREATE PROCEDURE NUCLEUS_GetProductByCode
(
	@ProductID	INT
)

AS

SELECT	Code,
	[Description]
FROM NucleusProducts
WHERE BrulinesProductID = @ProductID