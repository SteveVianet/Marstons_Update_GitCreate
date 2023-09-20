CREATE PROCEDURE [dbo].[UpdateSiteRegion]
(
	@EDISID		INT,
	@RegionID	INT,
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
	SET Region = @RegionID
	WHERE EDISID = @EDISID

	SET @UpdateID = @@DBTS

	RETURN 0

END
ELSE
BEGIN
	RETURN -1

END


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateSiteRegion] TO PUBLIC
    AS [dbo];

