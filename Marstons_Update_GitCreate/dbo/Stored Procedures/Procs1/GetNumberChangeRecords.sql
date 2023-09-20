CREATE PROCEDURE [dbo].[GetNumberChangeRecords]
(
	@EDISID		INT
)

AS

DECLARE @DBID INT

SELECT @DBID = PropertyValue 
FROM Configuration 
WHERE PropertyName = 'Service Owner ID'

EXEC [SQL1\SQL1].ServiceLogger.dbo.GetNumberChangeRecords @EDISID, @DBID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetNumberChangeRecords] TO PUBLIC
    AS [dbo];

