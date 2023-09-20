CREATE PROCEDURE [dbo].[GetVisitRecordAdmissionReasonByID]

	@AdmissionReasonID INT,
	@Description NVARCHAR(100) OUTPUT

AS

SET NOCOUNT ON

DECLARE @AdmissionReason AS TABLE ([ID] INT, [Description] NVARCHAR(100))
INSERT INTO @AdmissionReason EXEC [SQL1\SQL1].[ServiceLogger].[dbo].GetVRSAdmissionReason


SELECT @Description = [Description]
FROM VRSAdmissionReason
JOIN @AdmissionReason AS Admission ON Admission.[ID] = AdmissionReasonID
WHERE AdmissionReasonID = @AdmissionReasonID
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetVisitRecordAdmissionReasonByID] TO PUBLIC
    AS [dbo];

