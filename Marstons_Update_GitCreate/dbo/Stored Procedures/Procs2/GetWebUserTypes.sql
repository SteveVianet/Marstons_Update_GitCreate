CREATE PROCEDURE [dbo].[GetWebUserTypes] 

AS

SELECT ID, Description, AllSitesVisible
FROM UserTypes
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetWebUserTypes] TO PUBLIC
    AS [dbo];

