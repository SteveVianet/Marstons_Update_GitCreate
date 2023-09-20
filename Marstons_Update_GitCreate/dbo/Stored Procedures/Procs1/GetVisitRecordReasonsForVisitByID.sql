CREATE PROCEDURE dbo.GetVisitRecordReasonsForVisitByID
	@ReasonID INT,
	@IncludeDepricated BIT = 0,
	@ReasonDescription NVARCHAR(100) OUTPUT
AS

SET NOCOUNT ON

CREATE TABLE #Reasons ([ID] INT, [Description] NVARCHAR(100))
INSERT INTO #Reasons EXEC [SQL1\SQL1].[ServiceLogger].[dbo].GetVRSReasonForVisit


SELECT @ReasonDescription = [Description]
FROM VRSReasonForVisit
JOIN #Reasons AS Reasons  ON Reasons.[ID] = ReasonID
WHERE ReasonID = @ReasonID
AND (Depricated = 0 OR @IncludeDepricated = 1)


DROP TABLE #Reasons


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetVisitRecordReasonsForVisitByID] TO PUBLIC
    AS [dbo];

