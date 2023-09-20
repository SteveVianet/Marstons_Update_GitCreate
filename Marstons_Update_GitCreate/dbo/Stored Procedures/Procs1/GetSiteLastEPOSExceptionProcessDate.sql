
CREATE PROCEDURE [dbo].[GetSiteLastEPOSExceptionProcessDate]
(
	@EDISID		INT
)
AS

SELECT LastEPOSExceptionProcessDate
FROM Sites
WHERE EDISID = @EDISID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSiteLastEPOSExceptionProcessDate] TO PUBLIC
    AS [dbo];

