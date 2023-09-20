CREATE PROCEDURE [dbo].[GetWebEnabled]

AS

DECLARE @Enabled BIT

SELECT @Enabled = CAST(PropertyValue AS BIT)
FROM dbo.Configuration
WHERE PropertyName = 'WebAccessEnabled'

SELECT ISNULL(@Enabled, CAST(0 AS BIT)) AS WebSiteEnabled


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetWebEnabled] TO PUBLIC
    AS [dbo];

