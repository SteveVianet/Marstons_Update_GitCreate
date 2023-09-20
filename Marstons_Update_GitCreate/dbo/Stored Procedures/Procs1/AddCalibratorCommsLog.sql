CREATE PROCEDURE dbo.AddCalibratorCommsLog
(
	@EDISID			INT,
	@EDISTelNo		VARCHAR(50),
	@Message		VARCHAR(1000)
)

AS

DECLARE @DatabaseID INT

SELECT @DatabaseID = CAST(PropertyValue AS INTEGER)
FROM Configuration
WHERE PropertyName = 'Service Owner ID'

EXEC [EDISSQL1\SQL1].ServiceLogger.dbo.AddCalibratorCommsLog @DatabaseID, @EDISID, @EDISTelNo, @Message

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddCalibratorCommsLog] TO PUBLIC
    AS [dbo];

