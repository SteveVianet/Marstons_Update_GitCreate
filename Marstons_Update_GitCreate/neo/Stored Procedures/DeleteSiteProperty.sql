CREATE PROCEDURE [neo].[DeleteSiteProperty]
(
	@EDISID		INT,
	@PropertyID INT
)

AS

DELETE FROM dbo.SiteProperties
WHERE EDISID = @EDISID AND PropertyID = @PropertyID

GO
GRANT EXECUTE
    ON OBJECT::[neo].[DeleteSiteProperty] TO PUBLIC
    AS [dbo];

