
CREATE PROCEDURE [dbo].[GetVisitRecordVerificationByDescription]

	@VerificationDescription VARCHAR(1000),
	@ID INT OUTPUT

AS

SET NOCOUNT ON

DECLARE @Verification AS TABLE ([ID] INT, [Description] NVARCHAR(100))
INSERT INTO @Verification EXEC [SQL1\SQL1].[ServiceLogger].[dbo].GetVRSVerification

SELECT @ID = [ID]
FROM VRSVerification
JOIN @Verification AS Verification ON Verification.[ID] = VerificationID
WHERE [Description] = @VerificationDescription

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetVisitRecordVerificationByDescription] TO PUBLIC
    AS [dbo];

