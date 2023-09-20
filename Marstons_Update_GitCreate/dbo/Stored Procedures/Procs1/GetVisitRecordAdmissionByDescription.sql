
CREATE PROCEDURE [dbo].[GetVisitRecordAdmissionByDescription]

	@AdmissionDescription VARCHAR(1000),
	@ID INT OUTPUT

AS

SET NOCOUNT ON

DECLARE @Admission AS TABLE ([ID] INT, [Description] NVARCHAR(100))
INSERT INTO @Admission EXEC [SQL1\SQL1].[ServiceLogger].[dbo].GetVRSAdmission

SELECT @ID = [ID]
FROM VRSAdmission
JOIN @Admission AS Admission ON Admission.[ID] = AdmissionID
WHERE [Description] = @AdmissionDescription

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetVisitRecordAdmissionByDescription] TO PUBLIC
    AS [dbo];

