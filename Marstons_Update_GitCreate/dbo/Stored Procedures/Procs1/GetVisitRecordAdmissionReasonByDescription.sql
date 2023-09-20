
CREATE PROCEDURE [dbo].[GetVisitRecordAdmissionReasonByDescription]

	@AdmissionReasonDescription VARCHAR(1000),
	@ID INT OUTPUT

AS

SET NOCOUNT ON

DECLARE @AdmissionReason AS TABLE ([ID] INT, [Description] NVARCHAR(100))
INSERT INTO @AdmissionReason EXEC [SQL1\SQL1].[ServiceLogger].[dbo].GetVRSAdmissionReason

SELECT @ID = [ID]
FROM VRSAdmissionReason
JOIN @AdmissionReason AS Admission ON Admission.[ID] = AdmissionReasonID
WHERE [Description] = @AdmissionReasonDescription

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetVisitRecordAdmissionReasonByDescription] TO PUBLIC
    AS [dbo];

