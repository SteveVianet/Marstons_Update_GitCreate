---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE [dbo].[AddSiteProperty]
(
	@EDISID		INT,
	@PropertyName	VARCHAR(50),
	@Value		VARCHAR(255)
)

AS

DECLARE @PropertyID	INT

SELECT @PropertyID = [ID]
FROM dbo.Properties
WHERE [Name] = @PropertyName

IF @PropertyID IS NULL
BEGIN
	--Create the new Property and select the new Property's ID
	INSERT INTO dbo.Properties
		([Name])
	VALUES
		(@PropertyName)
	
	SELECT @PropertyID = @@IDENTITY
END

INSERT INTO dbo.SiteProperties
(EDISID, PropertyID, Value)
VALUES
(@EDISID, @PropertyID, @Value)

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddSiteProperty] TO PUBLIC
    AS [dbo];

