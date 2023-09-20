CREATE PROCEDURE [dbo].[GetVisitRecordAdmissionByID]

	@AdmissionID INT,
	@Description NVARCHAR(100) OUTPUT

AS

SET NOCOUNT ON

DECLARE @Admission AS TABLE ([ID] INT, [Description] NVARCHAR(100))
INSERT INTO @Admission EXEC [SQL1\SQL1].[ServiceLogger].[dbo].GetVRSAdmission


SELECT @Description = [Description]
FROM VRSAdmission
JOIN @Admission AS Admission ON Admission.[ID] = AdmissionID
WHERE AdmissionID = @AdmissionID
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetVisitRecordAdmissionByID] TO PUBLIC
    AS [dbo];

