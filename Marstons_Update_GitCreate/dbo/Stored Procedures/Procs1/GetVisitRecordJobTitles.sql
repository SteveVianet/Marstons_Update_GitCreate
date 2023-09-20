CREATE PROCEDURE [dbo].[GetVisitRecordJobTitles]
	@IncludeDepricated BIT = 1
AS

SET NOCOUNT ON

DECLARE @Jobs AS TABLE ([ID] INT, [Description] NVARCHAR(100))
INSERT INTO @Jobs EXEC [SQL1\SQL1].[ServiceLogger].[dbo].GetVRSMetOnSite

SELECT JobTitleID, [Description]
FROM VRSJobTitle
JOIN @Jobs AS Jobs ON Jobs.[ID] = JobTitleID
WHERE Depricated = 0 OR @IncludeDepricated = 1
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetVisitRecordJobTitles] TO PUBLIC
    AS [dbo];

