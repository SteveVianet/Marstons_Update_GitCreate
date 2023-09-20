CREATE PROCEDURE [dbo].[GetSchedulesLineCleaning]

AS
BEGIN
	
	SET NOCOUNT ON;

SELECT [ID],
	SUBSTRING([Description], CHARINDEX(':', [Description])+1, LEN([Description])) AS [Description],
	[Public],
	ExpiryDate
FROM dbo.Schedules
WHERE[Public] = 1
AND (ExpiryDate >= GETDATE() OR ExpiryDate IS NULL)
UNION
SELECT NULL,'All','',NULL
ORDER BY [Description] ASC

END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSchedulesLineCleaning] TO PUBLIC
    AS [dbo];

