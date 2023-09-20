CREATE PROCEDURE [dbo].[GetVisitRecordAccessDetailsByID]

	@AccessDetailsID INT,
	@Description NVARCHAR(100) OUTPUT

AS

SET NOCOUNT ON

DECLARE @Access AS TABLE ([ID] INT, [Description] NVARCHAR(100))
INSERT INTO @Access EXEC [SQL1\SQL1].[ServiceLogger].[dbo].GetVRSAccessDetails


SELECT @Description = [Description]
FROM VRSAccessDetail
JOIN @Access AS Access ON Access.[ID] = AccessDetailID
WHERE AccessDetailID = @AccessDetailsID
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetVisitRecordAccessDetailsByID] TO PUBLIC
    AS [dbo];

