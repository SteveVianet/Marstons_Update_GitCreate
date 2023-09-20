CREATE PROCEDURE UpdateSiteComment
(
	@EDISID		INT,
	@Comment	TEXT,
	@UpdateID	ROWVERSION = NULL	OUTPUT
)

AS

DECLARE @GlobalEDISID	INTEGER

SET NOCOUNT ON

IF 	(SELECT COUNT(*)
	FROM dbo.Sites 
	WHERE EDISID = @EDISID 
	AND UpdateID = @UpdateID) > 0 
     OR @UpdateID IS NULL
BEGIN
	UPDATE dbo.Sites
	SET Comment = @Comment
	WHERE EDISID = @EDISID

	/*
	SELECT @GlobalEDISID = GlobalEDISID
	FROM Sites
	WHERE EDISID = @EDISID

	IF @GlobalEDISID IS NOT NULL
	BEGIN
		EXEC [SQL2\SQL2].[Global].dbo.UpdateSiteComment @GlobalEDISID, @Comment, @UpdateID
	END
	*/

	SET @UpdateID = (SELECT UpdateID FROM Sites WHERE EDISID = @EDISID)

	RETURN 0

END
ELSE
BEGIN
	RETURN -1

END



GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateSiteComment] TO PUBLIC
    AS [dbo];

