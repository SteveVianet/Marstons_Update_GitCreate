CREATE PROCEDURE [dbo].[RebuildCalendar]
AS

IF OBJECT_ID('Calendar') IS NOT NULL DROP TABLE Calendar

SELECT * INTO dbo.Calendar FROM [EDISSQL1\SQL1].ServiceLogger.dbo.Calendar

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[RebuildCalendar] TO PUBLIC
    AS [dbo];

