CREATE PROCEDURE [dbo].[AddDownloadRequest2]
(
	@EDISID	INT
)

AS
DECLARE @Server VARCHAR(50)
DECLARE @Database VARCHAR(50)
DECLARE @When DATETIME

SET @Server = @@SERVERNAME
SET @Database = DB_NAME()
SET @When = GETDATE()

SET NOCOUNT ON

/*
UPDATE SiteProperties
SET Value = ''
FROM SiteProperties
JOIN Properties ON Properties.ID = SiteProperties.PropertyID
WHERE Properties.Name = 'Last GPRS connection' AND EDISID = @EDISID
*/

EXEC [EDISSQL1\SQL1].DownloadService.dbo.AddDownloadRequest @Server, @Database, @EDISID, @When, 1

