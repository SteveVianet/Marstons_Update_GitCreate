CREATE PROCEDURE [dbo].[UpdateSiteLocations] AS

DELETE FROM SiteLocations

INSERT INTO SiteLocations
(EDISID, LocationX, LocationY)
SELECT  Sites.EDISID,
		ISNULL(AllCodes.Lat, 0),
		ISNULL(AllCodes.Long, 0)
FROM Sites
LEFT JOIN (
	SELECT Postcode, PostcodeNoSpace, Long, Lat
	FROM [EDISSQL1\SQL1].ServiceLogger.dbo.PostcodesClean AS PostcodesClean
) AS AllCodes ON AllCodes.PostcodeNoSpace = REPLACE(UPPER(Sites.PostCode), ' ', '')


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateSiteLocations] TO PUBLIC
    AS [dbo];

