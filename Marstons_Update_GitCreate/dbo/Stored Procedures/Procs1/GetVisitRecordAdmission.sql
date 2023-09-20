CREATE PROCEDURE [dbo].[GetVisitRecordAdmission]
	@IncludeDepricated BIT = 1
AS

SET NOCOUNT ON

DECLARE @Admission AS TABLE ([ID] INT, [Description] NVARCHAR(100))
INSERT INTO @Admission EXEC [SQL1\SQL1].[ServiceLogger].[dbo].GetVRSAdmission

SELECT AdmissionID, [Description]
FROM VRSAdmission
JOIN @Admission AS Admission ON Admission.[ID] = AdmissionID
WHERE Depricated = 0 OR @IncludeDepricated = 1
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetVisitRecordAdmission] TO PUBLIC
    AS [dbo];

