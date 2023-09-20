CREATE PROCEDURE [dbo].[UpdateSiteClubMembership]
(	@EDISID		INTEGER,
	@Club		INTEGER,
	@UpdateID	ROWVERSION = NULL	OUTPUT
)

AS

SET XACT_ABORT ON

BEGIN TRAN

SET NOCOUNT ON

DECLARE @GlobalEDISID	INTEGER
DECLARE @GlobalOwnerID	INTEGER

-- If EDISID exists and UpdateID matches
IF 	(SELECT COUNT(*)
	FROM dbo.Sites 
	WHERE EDISID = @EDISID 
	AND UpdateID = @UpdateID) > 0 
     OR @UpdateID IS NULL
BEGIN
	UPDATE dbo.Sites
	SET 
		[ClubMembership] = @Club
	WHERE EDISID = @EDISID

	SET @UpdateID = @@DBTS

	COMMIT
	RETURN 0

END
ELSE
BEGIN
	COMMIT
	RETURN -1

END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateSiteClubMembership] TO PUBLIC
    AS [dbo];

