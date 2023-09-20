
CREATE PROCEDURE dbo.GetWebUserLastAuditDate


AS
BEGIN

	SET NOCOUNT ON;

	SELECT DATEADD(Day, 6, CAST(dbo.Configuration.PropertyValue AS DATETIME)) AS LastAuditDate
	FROM dbo.Configuration
	WHERE dbo.Configuration.PropertyName = 'AuditDate'
	
END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetWebUserLastAuditDate] TO PUBLIC
    AS [dbo];

