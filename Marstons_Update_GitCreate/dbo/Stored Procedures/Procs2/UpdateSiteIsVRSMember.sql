---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE UpdateSiteIsVRSMember
(
	@EDISID		INT,
	@IsVRSMember	BIT,
	@UpdateID	ROWVERSION = NULL	OUTPUT
)

AS


IF 	(SELECT COUNT(*)
	FROM Sites 
	WHERE EDISID = @EDISID 
	AND UpdateID = @UpdateID) > 0 
     OR @UpdateID IS NULL
BEGIN
	UPDATE dbo.Sites
	SET IsVRSMember = @IsVRSMember
	WHERE EDISID = @EDISID

	SET @UpdateID = (SELECT UpdateID FROM Sites WHERE EDISID = @EDISID)

	RETURN 0

END
ELSE
BEGIN
	RETURN -1

END


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateSiteIsVRSMember] TO PUBLIC
    AS [dbo];

