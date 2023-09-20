CREATE PROCEDURE [dbo].[GetVisitRecordAdmissionForByID]

	@AdmissionForID INT,
	@Description NVARCHAR(100) OUTPUT

AS

SET NOCOUNT ON

DECLARE @AdmissionFor AS TABLE ([ID] INT, [Description] NVARCHAR(100))
INSERT INTO @AdmissionFor EXEC [SQL1\SQL1].[ServiceLogger].[dbo].GetVRSAdmissionFor


SELECT @Description = [Description]
FROM VRSAdmissionFor
JOIN @AdmissionFor AS AdmissionFor ON AdmissionFor.[ID] = AdmissionForID
WHERE AdmissionForID = @AdmissionForID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetVisitRecordAdmissionForByID] TO PUBLIC
    AS [dbo];

