
CREATE PROCEDURE dbo.DeleteFaultStack
(
	@EDISID		INT,
	@Date		DATETIME,
	@Time		DATETIME,
	@Description	VARCHAR(255)
)

AS

DECLARE @FaultID	INT

SELECT @FaultID = [ID]
FROM dbo.MasterDates
WHERE [Date] = @Date
AND EDISID = @EDISID

DELETE FROM dbo.FaultStack
WHERE FaultID = @FaultID
AND [Time] = @Time
AND [Description] = @Description

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[DeleteFaultStack] TO PUBLIC
    AS [dbo];

