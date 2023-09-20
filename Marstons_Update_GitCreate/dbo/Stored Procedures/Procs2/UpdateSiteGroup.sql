CREATE PROCEDURE [dbo].[UpdateSiteGroup]
(
	@GroupID INTEGER,
	@Description VARCHAR(50),
	@TypeID INT
)

AS

UPDATE	dbo.SiteGroups
set Description = @Description,
     TypeID = @TypeID
Where ID = @GroupID
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateSiteGroup] TO PUBLIC
    AS [dbo];

