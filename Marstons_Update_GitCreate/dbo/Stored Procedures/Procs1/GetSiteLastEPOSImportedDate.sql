
CREATE PROCEDURE [dbo].[GetSiteLastEPOSImportedDate]
(
	@EDISID		INT
)
AS

SELECT LastEPOSImportedDate
FROM Sites
WHERE EDISID = @EDISID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSiteLastEPOSImportedDate] TO PUBLIC
    AS [dbo];

