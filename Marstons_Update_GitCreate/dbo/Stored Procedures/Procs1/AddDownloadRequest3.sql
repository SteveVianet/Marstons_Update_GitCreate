CREATE PROCEDURE [dbo].[AddDownloadRequest3]
(
	@SiteID    VARCHAR(50)
)

AS
DECLARE @Server VARCHAR(50)
DECLARE @Database VARCHAR(50)
DECLARE @When DATETIME
DECLARE @EDISID INT

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

SET @EDISID = 0

SELECT @EDISID = EDISID
FROM Sites
WHERE SiteID = @SiteID

IF @EDISID > 0
BEGIN
    EXEC [EDISSQL1\SQL1].DownloadService.dbo.AddDownloadRequest @Server, @Database, @EDISID, @When, 1
END

