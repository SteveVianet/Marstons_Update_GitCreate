CREATE PROCEDURE [dbo].[GetVisitRecordFurtherAction]
	@IncludeDepricated BIT = 1
AS

SET NOCOUNT ON

DECLARE @FurtherAction AS TABLE ([ID] INT, [Description] NVARCHAR(100))
INSERT INTO @FurtherAction EXEC [SQL1\SQL1].[ServiceLogger].[dbo].GetVRSFurtherAction

SELECT FurtherActionID, [Description]
FROM VRSFurtherAction
JOIN @FurtherAction AS FurtherAction ON FurtherAction.[ID] = FurtherActionID
WHERE Depricated = 0 OR @IncludeDepricated = 1
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetVisitRecordFurtherAction] TO PUBLIC
    AS [dbo];

