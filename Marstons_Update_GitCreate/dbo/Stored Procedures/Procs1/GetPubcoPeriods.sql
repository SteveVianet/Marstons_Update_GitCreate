CREATE PROCEDURE [dbo].[GetPubcoPeriods]
AS

DECLARE @DatabaseID INT

SELECT @DatabaseID = CAST(PropertyValue AS INTEGER)
FROM dbo.Configuration
WHERE PropertyName = 'Service Owner ID'

EXEC [EDISSQL1\SQL1].ServiceLogger.dbo.GetPubcoPeriods @DatabaseID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetPubcoPeriods] TO PUBLIC
    AS [dbo];

