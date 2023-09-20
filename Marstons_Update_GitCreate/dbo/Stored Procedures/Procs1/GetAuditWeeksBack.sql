CREATE PROCEDURE GetAuditWeeksBack
	
AS
BEGIN

	SET NOCOUNT ON;

	SELECT ISNULL(CAST(PropertyValue AS INTEGER), 1) AS WeeksBack

	FROM Configuration
	
        WHERE PropertyName = 'AuditWeeksBehind'

END
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetAuditWeeksBack] TO PUBLIC
    AS [dbo];

