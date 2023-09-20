
CREATE PROCEDURE [dbo].[GetVisitRecordTamperingEvidenceByDescription]

	@TamperingEvidenceDescription VARCHAR(1000),
	@ID INT OUTPUT

AS

SET NOCOUNT ON

DECLARE @Tampering AS TABLE ([ID] INT, [Description] NVARCHAR(100))
INSERT INTO @Tampering EXEC [SQL1\SQL1].[ServiceLogger].[dbo].GetVRSTamperingEvidence

SELECT @ID = [ID]
FROM VRSTamperingEvidence
JOIN @Tampering AS Tampering ON Tampering.[ID] = TamperingEvidenceID
WHERE [Description] = @TamperingEvidenceDescription

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetVisitRecordTamperingEvidenceByDescription] TO PUBLIC
    AS [dbo];

