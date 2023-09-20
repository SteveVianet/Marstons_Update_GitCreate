
CREATE PROCEDURE [dbo].[GetVisitRecordAdmissionForByDescription]

	@AdmissionForDescription VARCHAR(1000),
	@ID INT OUTPUT

AS

SET NOCOUNT ON

DECLARE @AdmissionFor AS TABLE ([ID] INT, [Description] NVARCHAR(100))
INSERT INTO @AdmissionFor EXEC [SQL1\SQL1].[ServiceLogger].[dbo].GetVRSAdmissionFor

SELECT @ID = [ID]
FROM VRSAdmissionFor
JOIN @AdmissionFor AS AdmissionFor ON AdmissionFor.[ID] = AdmissionForID
WHERE [Description] = @AdmissionForDescription

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetVisitRecordAdmissionForByDescription] TO PUBLIC
    AS [dbo];

