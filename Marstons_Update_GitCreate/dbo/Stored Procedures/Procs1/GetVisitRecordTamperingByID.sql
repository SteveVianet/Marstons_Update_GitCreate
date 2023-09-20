CREATE PROCEDURE [dbo].[GetVisitRecordTamperingByID]

	@TamperingID INT,
	@Description NVARCHAR(100) OUTPUT

AS

SET NOCOUNT ON

DECLARE @Tampering AS TABLE ([ID] INT, [Description] NVARCHAR(100))
INSERT INTO @Tampering EXEC [SQL1\SQL1].[ServiceLogger].[dbo].GetVRSTampering


SELECT @Description = [Description]
FROM VRSTampering
JOIN @Tampering AS Tampering ON Tampering.[ID] = TamperingID
WHERE TamperingID = @TamperingID
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetVisitRecordTamperingByID] TO PUBLIC
    AS [dbo];

