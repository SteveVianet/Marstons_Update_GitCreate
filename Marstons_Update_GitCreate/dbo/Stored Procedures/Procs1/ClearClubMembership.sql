
CREATE PROCEDURE [dbo].[ClearClubMembership]
(
	@EDISID INT = NULL
)
AS

UPDATE dbo.Sites SET ClubMembership = 0
WHERE ((EDISID = @EDISID) OR (@EDISID IS NULL))

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[ClearClubMembership] TO PUBLIC
    AS [dbo];

