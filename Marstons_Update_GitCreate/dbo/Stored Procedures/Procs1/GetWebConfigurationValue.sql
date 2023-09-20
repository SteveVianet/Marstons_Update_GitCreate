CREATE PROCEDURE GetWebConfigurationValue
	@PropertyName VARCHAR(255)

AS

SET NOCOUNT ON;

SELECT PropertyValue
FROM Configuration
WHERE PropertyName = @PropertyName


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetWebConfigurationValue] TO PUBLIC
    AS [dbo];

