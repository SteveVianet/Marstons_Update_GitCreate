CREATE PROCEDURE [dbo].[JSInstallDatesTemp]
(
	@SiteID		VARCHAR(100),
	@InstallDate	DATETIME
)
AS

SET NOCOUNT ON

DECLARE @EDISID INT
DECLARE @PropertyID INT
DECLARE @Value VARCHAR(50)

SELECT @EDISID = EDISID
FROM Sites
WHERE SiteID = @SiteID

SELECT @Value = Value, @PropertyID = Properties.[ID]
FROM SiteProperties
JOIN Properties ON Properties.[ID] = SiteProperties.PropertyID
WHERE [Name] = 'Installation Date Source'
AND EDISID = @EDISID

IF @Value IS NULL
BEGIN
	INSERT INTO SiteProperties
	(EDISID, PropertyID, Value)
	VALUES
	(@EDISID, @PropertyID, 'Lisa Collin')
	
END
ELSE
BEGIN
	UPDATE SiteProperties
	SET Value = 'Lisa Collin'
	WHERE EDISID = @EDISID
	AND PropertyID = @PropertyID
	
END

UPDATE Sites SET InstallationDate = @InstallDate WHERE EDISID = @EDISID

UPDATE SystemStock SET OldInstallDate = @InstallDate WHERE PreviousEDISID = @EDISID
