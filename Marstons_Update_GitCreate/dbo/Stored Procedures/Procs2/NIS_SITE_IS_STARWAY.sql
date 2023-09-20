CREATE PROCEDURE dbo.NIS_SITE_IS_STARWAY
(
	@EDISID	AS	INT
)
AS
DECLARE @SiteIsStarway 	AS int
SELECT     @SiteIsStarway  = COUNT(*)
FROM         dbo.Sites INNER JOIN
                      dbo.SystemTypes ON dbo.Sites.SystemTypeID = dbo.SystemTypes.ID
WHERE     (dbo.Sites.EDISID = @EDISID) AND (dbo.SystemTypes.Description = 'Starway')
RETURN @SiteIsStarway

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[NIS_SITE_IS_STARWAY] TO PUBLIC
    AS [dbo];

