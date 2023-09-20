CREATE PROCEDURE [dbo].[GetVisitRecordVerificationByID]

	@VerificationID INT,
	@Description NVARCHAR(100) OUTPUT

AS

SET NOCOUNT ON

DECLARE @Verification AS TABLE ([ID] INT, [Description] NVARCHAR(100))
INSERT INTO @Verification EXEC [SQL1\SQL1].[ServiceLogger].[dbo].GetVRSVerification


SELECT @Description = [Description]
FROM VRSVerification
JOIN @Verification AS Verification ON Verification.[ID] = VerificationID
WHERE VerificationID = @VerificationID
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetVisitRecordVerificationByID] TO PUBLIC
    AS [dbo];

