CREATE PROCEDURE [dbo].[UpdateSiteInstallationDate]
(
	@EDISID	INT,
	@InstallationDate	DATETIME
)

AS

UPDATE Sites
SET InstallationDate = @InstallationDate
WHERE EDISID = @EDISID AND @InstallationDate > '1990-01-01'


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateSiteInstallationDate] TO PUBLIC
    AS [dbo];

