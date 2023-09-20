
CREATE PROCEDURE [dbo].[GetVisitRecordJobTitleByDescription]

	@JobTitleDescription VARCHAR(1000),
	@ID INT OUTPUT

AS

SET NOCOUNT ON

DECLARE @Jobs AS TABLE ([ID] INT, [Description] NVARCHAR(100))
INSERT INTO @Jobs EXEC [SQL1\SQL1].[ServiceLogger].[dbo].GetVRSMetOnSite

SELECT @ID = [ID]
FROM VRSJobTitle
JOIN @Jobs AS Jobs ON Jobs.[ID] = JobTitleID
WHERE [Description] = @JobTitleDescription

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetVisitRecordJobTitleByDescription] TO PUBLIC
    AS [dbo];

