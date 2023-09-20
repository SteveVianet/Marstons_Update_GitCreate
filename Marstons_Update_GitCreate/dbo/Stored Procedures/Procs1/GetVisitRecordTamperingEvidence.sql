CREATE PROCEDURE [dbo].[GetVisitRecordTamperingEvidence]
	@IncludeDepricated BIT = 1
AS

SET NOCOUNT ON

DECLARE @Evidence AS TABLE ([ID] INT, [Description] NVARCHAR(100))
INSERT INTO @Evidence EXEC [SQL1\SQL1].[ServiceLogger].[dbo].GetVRSTamperingEvidence

SELECT TamperingEvidenceID, [Description]
FROM VRSTamperingEvidence
JOIN @Evidence AS Evidence ON Evidence.[ID] = TamperingEvidenceID
WHERE Depricated = 0 OR @IncludeDepricated = 1
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetVisitRecordTamperingEvidence] TO PUBLIC
    AS [dbo];

