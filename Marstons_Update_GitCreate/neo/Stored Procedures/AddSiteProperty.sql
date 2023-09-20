CREATE PROCEDURE [neo].[AddSiteProperty]
(
	@EDISID		INT,
	@PropertyID INT,
	@Value		VARCHAR(255)
)

AS

INSERT INTO dbo.SiteProperties
(EDISID, PropertyID, Value)
VALUES
(@EDISID, @PropertyID, @Value)

GO
GRANT EXECUTE
    ON OBJECT::[neo].[AddSiteProperty] TO PUBLIC
    AS [dbo];

