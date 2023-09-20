

CREATE PROCEDURE [dbo].[UpdateSiteCommunicationProviderID] 
(
	@EDISID			INT,
	@CommunicationProviderID	INT,
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
	SET CommunicationProviderID = @CommunicationProviderID
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
    ON OBJECT::[dbo].[UpdateSiteCommunicationProviderID] TO PUBLIC
    AS [dbo];

