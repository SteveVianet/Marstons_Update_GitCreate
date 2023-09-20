---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE DeleteSiteProperty
(
	@EDISID		INT,
	@PropertyName	VARCHAR(50)
)

AS

DECLARE @PropertyID	INT

SELECT @PropertyID = [ID]
FROM dbo.Properties
WHERE [Name] = @PropertyName

IF @PropertyID IS NULL
	RAISERROR ('Property does not exist', 16, 1)

DELETE FROM dbo.SiteProperties
WHERE EDISID = @EDISID
AND PropertyID = @PropertyID


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[DeleteSiteProperty] TO PUBLIC
    AS [dbo];

