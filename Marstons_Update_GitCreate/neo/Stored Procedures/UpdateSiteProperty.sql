CREATE PROCEDURE [neo].[UpdateSiteProperty]
(
	@EDISID		INT,
	@PropertyID INT,
	@Value		VARCHAR(255)
)

AS

UPDATE dbo.SiteProperties
set Value = @Value
where EDISID = @EDISID and PropertyID = @PropertyID

GO
GRANT EXECUTE
    ON OBJECT::[neo].[UpdateSiteProperty] TO PUBLIC
    AS [dbo];

