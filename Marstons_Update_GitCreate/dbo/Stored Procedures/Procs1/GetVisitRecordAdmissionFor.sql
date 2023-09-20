CREATE PROCEDURE [dbo].[GetVisitRecordAdmissionFor]
	@IncludeDepricated BIT = 1
AS

SET NOCOUNT ON

DECLARE @AdmissionFor AS TABLE ([ID] INT, [Description] NVARCHAR(100))
INSERT INTO @AdmissionFor EXEC [SQL1\SQL1].[ServiceLogger].[dbo].GetVRSAdmissionFor

SELECT AdmissionForID, [Description]
FROM VRSAdmissionFor
JOIN @AdmissionFor AS AdmissionFor ON AdmissionFor.[ID] = AdmissionForID
WHERE Depricated = 0 OR @IncludeDepricated = 1
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetVisitRecordAdmissionFor] TO PUBLIC
    AS [dbo];

