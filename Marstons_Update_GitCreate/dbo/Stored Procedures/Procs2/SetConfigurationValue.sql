CREATE PROCEDURE [dbo].[SetConfigurationValue]
(
	@PropertyName		VARCHAR(255),
	@PropertyValue		VARCHAR(255)
)

AS

SET NOCOUNT ON

DECLARE @NumRows	INT

SELECT @NumRows = COUNT(*)
FROM dbo.Configuration
WHERE PropertyName = @PropertyName

IF @NumRows = 1
BEGIN
	UPDATE dbo.Configuration
	SET PropertyValue = @PropertyValue
	WHERE PropertyName = @PropertyName

	IF @PropertyName = 'AuditDate'
	BEGIN
		UPDATE dbo.Configuration
		SET PropertyValue = '1'
		WHERE PropertyName = 'Web Audit Date Changed'
	
	END
END

IF @NumRows = 0
BEGIN
	INSERT INTO dbo.Configuration
	(PropertyName, PropertyValue)
	VALUES
	(@PropertyName, @PropertyValue)
END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[SetConfigurationValue] TO PUBLIC
    AS [dbo];

