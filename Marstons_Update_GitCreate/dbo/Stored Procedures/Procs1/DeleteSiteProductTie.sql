CREATE PROCEDURE DeleteSiteProductTie
(
	@EDISID 	INT,
	@ProductID	INT
)

AS

SET NOCOUNT ON

/*
DECLARE @GlobalEDISID	INTEGER
DECLARE @GlobalProductID	INTEGER

SELECT @GlobalEDISID = GlobalEDISID
FROM Sites
WHERE EDISID = @EDISID

IF @GlobalEDISID IS NOT NULL
BEGIN
	SELECT @GlobalProductID = GlobalID
	FROM Products
	WHERE [ID] = @ProductID

	EXEC [SQL2\SQL2].[Global].dbo.DeleteProductTie @GlobalEDISID, @GlobalProductID
END
*/

DELETE FROM dbo.SiteProductTies
WHERE EDISID = @EDISID
AND ProductID = @ProductID


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[DeleteSiteProductTie] TO PUBLIC
    AS [dbo];

