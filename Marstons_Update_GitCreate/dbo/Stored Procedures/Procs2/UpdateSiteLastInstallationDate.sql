CREATE PROCEDURE [dbo].[UpdateSiteLastInstallationDate]
(
	@EDISID	INT,
	@LastInstallationDate	DATETIME
)

AS

UPDATE Sites
SET LastInstallationDate = @LastInstallationDate
WHERE EDISID = @EDISID AND @LastInstallationDate > '1990-01-01'

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateSiteLastInstallationDate] TO PUBLIC
    AS [dbo];

