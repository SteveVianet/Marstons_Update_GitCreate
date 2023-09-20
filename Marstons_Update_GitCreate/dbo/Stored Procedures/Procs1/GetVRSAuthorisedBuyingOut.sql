CREATE PROCEDURE [dbo].[GetVRSAuthorisedBuyingOut]
(
	@From		DATETIME,
	@To			DATETIME,
	@EDISID		INT = NULL
)
AS

SELECT	SiteVRSAuthorisedBuyingOut.ID,
		SiteVRSAuthorisedBuyingOut.EDISID,
		Sites.SiteID,
		SiteVRSAuthorisedBuyingOut.ProductID,
		Products.[Description] AS Product,
		AuthorisationDate,
		QuantityGallons,
		SiteVRSAuthorisedBuyingOut.[Filename],
	    SiteVRSAuthorisedBuyingOut.ImportedOn
FROM SiteVRSAuthorisedBuyingOut
JOIN Sites ON Sites.EDISID = SiteVRSAuthorisedBuyingOut.EDISID
JOIN Products ON Products.ID = SiteVRSAuthorisedBuyingOut.ProductID
WHERE (SiteVRSAuthorisedBuyingOut.EDISID = @EDISID OR @EDISID IS NULL)
AND (AuthorisationDate BETWEEN @From AND @To)
ORDER BY AuthorisationDate DESC

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetVRSAuthorisedBuyingOut] TO PUBLIC
    AS [dbo];

