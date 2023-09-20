CREATE PROCEDURE [dbo].[GetVisitRecordTamperingEvidenceByID]

	@TamperingEvidenceID INT,
	@Description NVARCHAR(100) OUTPUT

AS

SET NOCOUNT ON

DECLARE @Tampering AS TABLE ([ID] INT, [Description] NVARCHAR(100))
INSERT INTO @Tampering EXEC [SQL1\SQL1].[ServiceLogger].[dbo].GetVRSTamperingEvidence


SELECT @Description = [Description]
FROM VRSTamperingEvidence
JOIN @Tampering AS Tampering ON Tampering.[ID] = TamperingEvidenceID
WHERE TamperingEvidenceID = @TamperingEvidenceID
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetVisitRecordTamperingEvidenceByID] TO PUBLIC
    AS [dbo];

