CREATE PROCEDURE dbo.UpdateSiteProperty
(
	@EDISID		INT,
	@PropertyName	VARCHAR(50),
	@NewValue		VARCHAR(255)
)

AS

DECLARE @PropertyID INT
DECLARE @SitePropertyExists INT

SET NOCOUNT ON

-- Ensure Property exists in this database
SELECT @PropertyID = [ID]
FROM dbo.Properties
WHERE [Name] = @PropertyName

IF @PropertyID IS NULL
BEGIN
	INSERT INTO dbo.Properties
	([Name])
	VALUES
	(@PropertyName)

	SET @PropertyID = @@IDENTITY
END

-- Ensure property is assigned to this site
SELECT @SitePropertyExists = COUNT(*)
FROM dbo.SiteProperties
WHERE [PropertyID] = @PropertyID AND EDISID = @EDISID

IF @SitePropertyExists < 1
BEGIN
	INSERT INTO dbo.SiteProperties
	([EDISID], [PropertyID], [Value])
	VALUES
	(@EDISID, @PropertyID, @NewValue)
END
ELSE
BEGIN
	UPDATE dbo.SiteProperties
	SET Value = @NewValue
	FROM dbo.SiteProperties
	JOIN dbo.Properties
	ON Properties.[ID] = SiteProperties.PropertyID
	WHERE SiteProperties.EDISID = @EDISID
	AND Properties.[Name] = @PropertyName
END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateSiteProperty] TO PUBLIC
    AS [dbo];

