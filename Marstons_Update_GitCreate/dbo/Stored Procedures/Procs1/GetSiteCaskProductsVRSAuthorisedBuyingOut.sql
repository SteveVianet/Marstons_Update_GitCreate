
CREATE PROCEDURE dbo.GetSiteCaskProductsVRSAuthorisedBuyingOut
(
	@EDISID		INT,
	@From		DATE,
	@To			DATE
)
AS

SET NOCOUNT ON

SELECT	EDISID,
		SUM(QuantityGallons) AS QuantityGallons
FROM SiteVRSAuthorisedBuyingOut
JOIN Products ON Products.ID = SiteVRSAuthorisedBuyingOut.ProductID
WHERE EDISID = @EDISID
AND AuthorisationDate BETWEEN @From AND @To
AND Products.IsCask = 1
GROUP BY EDISID, ProductID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSiteCaskProductsVRSAuthorisedBuyingOut] TO PUBLIC
    AS [dbo];

