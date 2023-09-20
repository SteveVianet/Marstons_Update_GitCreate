
CREATE PROCEDURE [dbo].[UpdateSiteQuality]
(
	@EDISID		INT,
	@Quality		BIT,
	@UpdateID		ROWVERSION = NULL	OUTPUT
)

AS

SET NOCOUNT ON

UPDATE Sites
SET	Quality = @Quality
WHERE [EDISID] = @EDISID

SET @UpdateID = (SELECT UpdateID FROM Sites WHERE EDISID = @EDISID)

EXEC dbo.UpdateSiteQualityHistory @EDISID, @Quality

RETURN 0

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateSiteQuality] TO PUBLIC
    AS [dbo];

