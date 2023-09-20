CREATE PROCEDURE dbo.UpdateFaultStackDescription
(
	@EDISID		INT,
	@Date			DATETIME,
	@Time			DATETIME,
	@Description		VARCHAR(255),
	@NewDescription	VARCHAR(255)
)

AS

DECLARE @FaultID	INT

SELECT @FaultID = [ID]
FROM dbo.MasterDates
WHERE [Date] = @Date
AND EDISID = @EDISID

UPDATE dbo.FaultStack
SET [Description] = @NewDescription
WHERE FaultID = @FaultID
AND [Time] = @Time
AND [Description] = @Description

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateFaultStackDescription] TO PUBLIC
    AS [dbo];

