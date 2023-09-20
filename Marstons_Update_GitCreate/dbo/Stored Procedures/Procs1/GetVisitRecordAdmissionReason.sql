CREATE PROCEDURE [dbo].[GetVisitRecordAdmissionReason]
	@IncludeDepricated BIT = 1
AS

SET NOCOUNT ON

DECLARE @AdmissionReason AS TABLE ([ID] INT, [Description] NVARCHAR(100))
INSERT INTO @AdmissionReason EXEC [SQL1\SQL1].[ServiceLogger].[dbo].GetVRSAdmissionReason

SELECT AdmissionReasonID, [Description]
FROM VRSAdmissionReason
JOIN @AdmissionReason AS Admission ON Admission.[ID] = AdmissionReasonID
WHERE Depricated = 0 OR @IncludeDepricated = 1

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetVisitRecordAdmissionReason] TO PUBLIC
    AS [dbo];

