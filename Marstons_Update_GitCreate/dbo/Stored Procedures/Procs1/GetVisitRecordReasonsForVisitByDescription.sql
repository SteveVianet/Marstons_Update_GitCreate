
CREATE PROCEDURE [dbo].[GetVisitRecordReasonsForVisitByDescription]
	@ReasonDescription VARCHAR(1000),
	@IncludeDepricated BIT = 0,
	@ID INT OUTPUT
AS

SET NOCOUNT ON

CREATE TABLE #Reasons ([ID] INT, [Description] NVARCHAR(100))
INSERT INTO #Reasons EXEC [SQL1\SQL1].[ServiceLogger].[dbo].GetVRSReasonForVisit

SELECT @ID = [ID]
FROM VRSReasonForVisit
JOIN #Reasons AS Reasons  ON Reasons.[ID] = ReasonID
WHERE [Description] = @ReasonDescription
AND (Depricated = 0 OR @IncludeDepricated = 1)

DROP TABLE #Reasons

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetVisitRecordReasonsForVisitByDescription] TO PUBLIC
    AS [dbo];

