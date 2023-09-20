
CREATE PROCEDURE [dbo].[GetVisitRecordTamperingByDescription]

	@TamperingDescription VARCHAR(1000),
	@ID INT OUTPUT

AS

SET NOCOUNT ON

DECLARE @Tampering AS TABLE ([ID] INT, [Description] NVARCHAR(100))
INSERT INTO @Tampering EXEC [SQL1\SQL1].[ServiceLogger].[dbo].GetVRSTampering

SELECT @ID = [ID]
FROM VRSTampering
JOIN @Tampering AS Tampering ON Tampering.[ID] = TamperingID
WHERE [Description] = @TamperingDescription

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetVisitRecordTamperingByDescription] TO PUBLIC
    AS [dbo];

