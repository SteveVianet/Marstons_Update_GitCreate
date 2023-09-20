CREATE PROCEDURE [dbo].[GetVisitRecordReasonsForVisit]
	@IncludeDepricated BIT = 1
AS

SET NOCOUNT ON

DECLARE @Reasons AS TABLE ([ID] INT, [Description] NVARCHAR(100))
INSERT INTO @Reasons EXEC [SQL1\SQL1].[ServiceLogger].[dbo].GetVRSReasonForVisit


SELECT ReasonID, [Description]
FROM VRSReasonForVisit
JOIN @Reasons AS Reasons  ON Reasons.[ID] = ReasonID
WHERE Depricated = 0 OR @IncludeDepricated = 1
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetVisitRecordReasonsForVisit] TO PUBLIC
    AS [dbo];

