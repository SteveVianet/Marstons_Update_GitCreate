CREATE PROCEDURE [dbo].[GetVisitRecordAccessDetails]
	@IncludeDepricated BIT = 1
AS

SET NOCOUNT ON

DECLARE @Access AS TABLE ([ID] INT, [Description] NVARCHAR(100))
INSERT INTO @Access EXEC [SQL1\SQL1].[ServiceLogger].[dbo].GetVRSAccessDetails

SELECT AccessDetailID, [Description]
FROM VRSAccessDetail
JOIN @Access AS Access ON Access.[ID] = AccessDetailID
WHERE Depricated = 0 OR @IncludeDepricated = 1
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetVisitRecordAccessDetails] TO PUBLIC
    AS [dbo];

