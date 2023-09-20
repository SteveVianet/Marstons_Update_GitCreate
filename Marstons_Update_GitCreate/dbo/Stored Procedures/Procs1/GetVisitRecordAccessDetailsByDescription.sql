CREATE PROCEDURE [dbo].[GetVisitRecordAccessDetailsByDescription]

	@AccessDetailsDescription VARCHAR(1000),
	@ID INT OUTPUT

AS

SET NOCOUNT ON

DECLARE @Access AS TABLE ([ID] INT, [Description] NVARCHAR(100))
INSERT INTO @Access EXEC [SQL1\SQL1].[ServiceLogger].[dbo].GetVRSAccessDetails

SELECT @ID = [ID]
FROM VRSAccessDetail
JOIN @Access AS Access ON Access.[ID] = AccessDetailID
WHERE [Description] = @AccessDetailsDescription

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetVisitRecordAccessDetailsByDescription] TO PUBLIC
    AS [dbo];

