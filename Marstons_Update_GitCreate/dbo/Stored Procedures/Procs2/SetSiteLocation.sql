---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE SetSiteLocation
(
	@EDISID		INT,
	@LocationX	FLOAT,
	@LocationY	FLOAT
)

AS

DECLARE @LocationCount	INT

SELECT @LocationCount = COUNT(*)
FROM SiteLocations
WHERE EDISID = @EDISID

IF @LocationCount > 0
BEGIN
	UPDATE SiteLocations
	SET 	LocationX = @LocationX,
		LocationY = @LocationY
	WHERE EDISID = @EDISID
END
ELSE IF @LocationCount = 0
BEGIN
	INSERT INTO SiteLocations
	(EDISID, LocationX, LocationY)
	VALUES
	(@EDISID, @LocationX, @LocationY)
END


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[SetSiteLocation] TO PUBLIC
    AS [dbo];

