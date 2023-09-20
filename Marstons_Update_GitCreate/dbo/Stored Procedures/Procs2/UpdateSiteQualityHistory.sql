
CREATE PROCEDURE [dbo].[UpdateSiteQualityHistory]
(
	@EDISID				INT,
	@NewQualitySetting	BIT
)
AS

SET NOCOUNT ON

DECLARE @SiteIsCurrentlyQuality BIT = 0
DECLARE @SiteQualityHistoryExists BIT = 0

IF @NewQualitySetting = 1
BEGIN
	SELECT @SiteIsCurrentlyQuality = CASE WHEN COUNT(*) > 0 THEN 1 ELSE 0 END
	FROM SiteQualityHistory
	WHERE EDISID = @EDISID
	AND QualityEnd IS NULL

	SELECT @SiteQualityHistoryExists = CASE WHEN COUNT(*) > 0 THEN 1 ELSE 0 END
	FROM SiteQualityHistory
	WHERE EDISID = @EDISID 
	AND QualityStart = CAST(GETDATE() AS DATE)

	IF @SiteIsCurrentlyQuality = 0 AND @SiteQualityHistoryExists = 0
	BEGIN
		INSERT INTO SiteQualityHistory
		(EDISID, QualityStart, QualityEnd)
		VALUES
		(@EDISID, CAST(GETDATE() AS DATE), NULL)

	END
END
ELSE
BEGIN
	UPDATE SiteQualityHistory
	SET QualityEnd = CAST(DATEADD(DAY, -1, GETDATE()) AS DATE),
		QualityStart = CASE WHEN CAST(DATEADD(DAY, -1, GETDATE()) AS DATE) < QualityStart THEN CAST(DATEADD(DAY, -1, GETDATE()) AS DATE) ELSE QualityStart END
	WHERE EDISID = @EDISID
	AND QualityEnd IS NULL
	
END

GRANT EXECUTE ON dbo.UpdateSiteQualityHistory TO [public]

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateSiteQualityHistory] TO PUBLIC
    AS [dbo];

