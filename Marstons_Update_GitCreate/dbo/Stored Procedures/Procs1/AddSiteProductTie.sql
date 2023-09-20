CREATE PROCEDURE AddSiteProductTie
(
	@EDISID 	INT,
	@ProductID	INT,
	@Tied		BIT
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

	EXEC [SQL2\SQL2].[Global].dbo.AddSiteProductTie @GlobalEDISID, @GlobalProductID, @Tied
END
*/

INSERT INTO dbo.SiteProductTies
(EDISID, ProductID, Tied)
VALUES
(@EDISID, @ProductID, @Tied)


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddSiteProductTie] TO PUBLIC
    AS [dbo];

