CREATE PROCEDURE [dbo].[GetVisitRecordActionsTaken]
	@IncludeDepricated BIT = 1
AS

SET NOCOUNT ON

DECLARE @Actions AS TABLE ([ID] INT, [Description] NVARCHAR(100))
INSERT @Actions EXEC [SQL1\SQL1].[ServiceLogger].[dbo].GetVRSActionsTaken


SELECT ActionTakenID, [Description]
FROM VRSActionTakenByBDM
JOIN @Actions AS Actions ON Actions.[ID] = ActionTakenID
WHERE Depricated = 0 OR @IncludeDepricated = 1
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetVisitRecordActionsTaken] TO PUBLIC
    AS [dbo];

