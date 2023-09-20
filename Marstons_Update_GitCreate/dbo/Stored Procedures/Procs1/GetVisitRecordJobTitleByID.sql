CREATE PROCEDURE [dbo].[GetVisitRecordJobTitleByID]

	@JobTitleID INT,
	@Description NVARCHAR(100) OUTPUT

AS

SET NOCOUNT ON

DECLARE @Jobs AS TABLE ([ID] INT, [Description] NVARCHAR(100))
INSERT INTO @Jobs EXEC [SQL1\SQL1].[ServiceLogger].[dbo].GetVRSMetOnSite


SELECT @Description = [Description]
FROM VRSJobTitle
JOIN @Jobs AS Jobs ON Jobs.[ID] = JobTitleID
WHERE JobTitleID = @JobTitleID
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetVisitRecordJobTitleByID] TO PUBLIC
    AS [dbo];

