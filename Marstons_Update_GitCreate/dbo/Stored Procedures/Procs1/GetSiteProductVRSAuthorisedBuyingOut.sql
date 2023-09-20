

CREATE PROCEDURE dbo.GetSiteProductVRSAuthorisedBuyingOut
(
	@EDISID		INT,
	@ProductID	INT,
	@From		DATE,
	@To			DATE
)
AS

SET NOCOUNT ON

DECLARE @ValidProducts TABLE(ProductID INT)
DECLARE @ProductGroupID INT = NULL

SELECT @ProductGroupID = ProductGroupID
FROM ProductGroupProducts
JOIN ProductGroups ON ProductGroups.ID = ProductGroupProducts.ProductGroupID
WHERE ProductID = @ProductID
AND ProductGroups.TypeID = 1

IF @ProductGroupID IS NOT NULL
BEGIN
	INSERT INTO @ValidProducts
	(ProductID)
	SELECT ProductID
	FROM ProductGroupProducts
	WHERE ProductGroupID = @ProductGroupID

END
ELSE
BEGIN
	INSERT INTO @ValidProducts
	(ProductID)
	SELECT @ProductID

END

SELECT	EDISID,
		ProductID,
		SUM(QuantityGallons) AS QuantityGallons
FROM SiteVRSAuthorisedBuyingOut
WHERE EDISID = @EDISID
AND ProductID IN (SELECT ProductID FROM @ValidProducts)
AND AuthorisationDate BETWEEN @From AND @To
GROUP BY EDISID, ProductID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSiteProductVRSAuthorisedBuyingOut] TO PUBLIC
    AS [dbo];

