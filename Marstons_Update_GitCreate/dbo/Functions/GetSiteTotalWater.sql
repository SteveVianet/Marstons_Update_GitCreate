CREATE FUNCTION [dbo].[GetSiteTotalWater]
(
	@EDISID			INT,
	@From			DATETIME,
	@To				DATETIME,
	@IncludeCasks	BIT,
	@IncludeKegs	BIT
)
RETURNS FLOAT
AS
BEGIN
	DECLARE @TotalVolume FLOAT
	DECLARE @Sites TABLE(EDISID INT NOT NULL, CellarID INT NOT NULL IDENTITY)
	DECLARE @SiteGroupID INT
	DECLARE @SiteOnline DATETIME

	SELECT @SiteOnline = SiteOnline
	FROM dbo.Sites
	WHERE EDISID = @EDISID

	INSERT INTO @Sites
	(EDISID)
	SELECT @EDISID AS EDISID

	SELECT @SiteGroupID = SiteGroupID
	FROM SiteGroupSites
	JOIN SiteGroups ON SiteGroups.ID = SiteGroupSites.SiteGroupID
	WHERE TypeID = 1 AND EDISID = @EDISID

	INSERT INTO @Sites
	(EDISID)
	SELECT EDISID
	FROM SiteGroupSites
	WHERE SiteGroupID = @SiteGroupID AND EDISID <> @EDISID

	SELECT @TotalVolume = COALESCE(SUM(Volume)/8.0, 0)
	FROM WaterStack
	JOIN MasterDates ON MasterDates.[ID] = WaterStack.WaterID
	JOIN @Sites AS RelevantSites ON RelevantSites.EDISID = MasterDates.EDISID
	WHERE MasterDates.[Date] BETWEEN @From AND @To
	AND MasterDates.[Date] >= @SiteOnline
	AND (dbo.GetSitePumpIsCask(@EDISID, WaterStack.Line, MasterDates.Date) = 0 OR @IncludeCasks = 1)
	AND (dbo.GetSitePumpIsKeg(@EDISID, WaterStack.Line, MasterDates.Date) = 0 OR @IncludeKegs = 1)
	AND (dbo.GetSitePumpIsWater(@EDISID, WaterStack.Line, MasterDates.Date) = 0)

	RETURN @TotalVolume

END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSiteTotalWater] TO PUBLIC
    AS [dbo];

