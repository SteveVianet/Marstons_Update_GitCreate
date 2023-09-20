
CREATE PROCEDURE [dbo].[GetSiteExceptionStatus]
(
	@EDISID		INT
)
AS

SET NOCOUNT ON

SELECT	Owners.UseExceptionReporting,
		Sites.LastEPOSImportedDate,
		Sites.LastEPOSExceptionProcessDate
FROM Sites
JOIN Owners ON Owners.ID = Sites.OwnerID
WHERE Sites.EDISID = @EDISID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSiteExceptionStatus] TO PUBLIC
    AS [dbo];

