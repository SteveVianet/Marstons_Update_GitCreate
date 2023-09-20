CREATE PROCEDURE [dbo].[GetFileTypes]

AS

SELECT	[ID],
	[Description]
FROM dbo.FileTypes

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetFileTypes] TO PUBLIC
    AS [dbo];

