CREATE PROCEDURE [dbo].[UpdateOwnershipStatus] 
(
	@EDISID			INT,
	@OwnershipStatus		INT,
	@UpdateID	ROWVERSION = NULL	OUTPUT
)
AS

IF 	(SELECT COUNT(*)
	FROM dbo.Sites 
	WHERE EDISID = @EDISID 
	AND UpdateID = @UpdateID) > 0 
     	OR @UpdateID IS NULL
BEGIN
	UPDATE dbo.Sites
	SET OwnershipStatus = @OwnershipStatus
	WHERE EDISID = @EDISID

	SET @UpdateID = (SELECT UpdateID FROM dbo.Sites WHERE EDISID = @EDISID)

	RETURN 0

END
ELSE
BEGIN
	RETURN -1

END
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateOwnershipStatus] TO PUBLIC
    AS [dbo];

