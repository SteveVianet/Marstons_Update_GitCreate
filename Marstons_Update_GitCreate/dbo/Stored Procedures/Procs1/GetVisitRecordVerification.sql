CREATE PROCEDURE [dbo].[GetVisitRecordVerification]
	@IncludeDepricated BIT = 1
AS

SET NOCOUNT ON

DECLARE @Verification AS TABLE ([ID] INT, [Description] NVARCHAR(100))
INSERT INTO @Verification EXEC [SQL1\SQL1].[ServiceLogger].[dbo].GetVRSVerification

SELECT VerificationID, [Description]
FROM VRSVerification
JOIN @Verification AS Verification ON Verification.[ID] = VerificationID
WHERE Depricated = 0 OR @IncludeDepricated = 1
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetVisitRecordVerification] TO PUBLIC
    AS [dbo];

