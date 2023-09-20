CREATE PROCEDURE [dbo].[GetHistoricalFont]
(
	@EDISID		INTEGER,
	@Pump		INTEGER = NULL,
	@Date		DATETIME,
	@ToDate		DATETIME = NULL,
	@ShowNotInUse		BIT = 1,
	@ShowWater		BIT = 1,
	@IncludeMultipleCellars	BIT = 0
)

AS

SET NOCOUNT ON

DECLARE @Sites TABLE(EDISID INT NOT NULL, CellarID INT NOT NULL IDENTITY)
DECLARE @SiteGroupID INT
DECLARE @SitePumpCounts TABLE(Counter INT IDENTITY(1,1) PRIMARY KEY, EDISID INT NOT NULL, MaxPump INT NOT NULL)
DECLARE @SitePumpOffsets TABLE(EDISID INT NOT NULL PRIMARY KEY, PumpOffset INT NOT NULL)
DECLARE @AllSitePumps TABLE(PumpID INT NOT NULL, LocationID INT NOT NULL, ProductID INT NOT NULL)
DECLARE @SiteOnline DATETIME

SELECT @SiteOnline = SiteOnline
FROM dbo.Sites
WHERE EDISID = @EDISID

IF @IncludeMultipleCellars = 1
BEGIN
	-- Find out which EDISIDs are relevant (plough through SiteGroups)
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

	-- Get pumps for secondary sites (note that 1st EDISID IN @Sites is primary site)
	INSERT INTO @SitePumpCounts (EDISID, MaxPump)
	SELECT PumpSetup.EDISID, MAX(Pump)
	FROM PumpSetup
	JOIN @Sites AS Sites ON Sites.EDISID = PumpSetup.EDISID
	WHERE (ValidFrom <= @ToDate)
	AND (ISNULL(ValidTo, @ToDate) >= @Date)
	AND (ISNULL(ValidTo, @ToDate) >= @SiteOnline)
	GROUP BY PumpSetup.EDISID, Sites.CellarID
	ORDER BY CellarID

	INSERT INTO @SitePumpOffsets (EDISID, PumpOffset)
	SELECT MainCounts.EDISID, COALESCE(QuaternaryCounts.MaxPump+TertiaryCounts.MaxPump+SecondaryCounts.MaxPump, TertiaryCounts.MaxPump+SecondaryCounts.MaxPump, SecondaryCounts.MaxPump, 0)
	FROM @SitePumpCounts AS MainCounts
	LEFT JOIN @SitePumpCounts AS SecondaryCounts ON SecondaryCounts.Counter+1 = MainCounts.Counter
	LEFT JOIN @SitePumpCounts AS TertiaryCounts ON TertiaryCounts.Counter+2 = MainCounts.Counter
	LEFT JOIN @SitePumpCounts AS QuaternaryCounts ON QuaternaryCounts.Counter+3 = MainCounts.Counter

	INSERT INTO @AllSitePumps (PumpID, LocationID, ProductID)
	SELECT Pump+PumpOffset, LocationID, PumpSetup.ProductID
	FROM PumpSetup
	JOIN @Sites AS Sites ON Sites.EDISID = PumpSetup.EDISID
	JOIN @SitePumpOffsets AS SitePumpOffsets ON SitePumpOffsets.EDISID = PumpSetup.EDISID
	JOIN Products ON Products.[ID] = PumpSetup.ProductID
	WHERE (ValidFrom <= @ToDate)
	AND (ISNULL(ValidTo, @ToDate) >= @Date)
	AND (ISNULL(ValidTo, @ToDate) >= @SiteOnline)
	AND (PumpSetup.InUse = 1 OR @ShowNotInUse = 1)

	--SELECT * FROM @AllSitePumps

	SELECT Pump + PumpOffset AS Pump,
		Pump AS SitePump,
		PumpSetup.EDISID,
		 dbo.PumpSetup.ProductID,
		 dbo.PumpSetup.LocationID,
		 InUse,
		 BarPosition,
		 ValidFrom,
		 ValidTo
	FROM dbo.PumpSetup JOIN dbo.Products ON dbo.PumpSetup.ProductID = dbo.Products.ID
	JOIN @SitePumpOffsets AS SitePumpOffsets ON SitePumpOffsets.EDISID = dbo.PumpSetup.EDISID
	JOIN @AllSitePumps AS AllSitePumps ON AllSitePumps.PumpID = PumpSetup.Pump + PumpOffset
	WHERE (Pump + PumpOffset = @Pump OR @Pump IS NULL)
	AND dbo.PumpSetup.EDISID IN (SELECT EDISID FROM @Sites)
	AND ((ValidFrom <= @Date AND @ToDate IS NULL) OR ((@Date <= ValidTo AND @ToDate >= ValidFrom) OR (@ToDate >= ValidFrom AND ValidTo IS NULL)))
	AND (ValidTo >= @Date OR ValidTo IS NULL)
	AND (InUse = 1 OR @ShowNotInUse = 1)
	AND (IsWater = 0 OR @ShowWater = 1)
	GROUP BY Pump + PumpOffset, Pump, PumpSetup.EDISID, dbo.PumpSetup.ProductID, dbo.PumpSetup.LocationID, InUse, BarPosition, ValidFrom, ValidTo
	ORDER BY Pump + PumpOffset
END
ELSE
BEGIN
	SELECT Pump,
		 ProductID,
		 LocationID,
		 InUse,
		 BarPosition,
		 ValidFrom,
		 ValidTo,
		 Products.Description
	FROM dbo.PumpSetup JOIN dbo.Products ON dbo.PumpSetup.ProductID = dbo.Products.ID
	WHERE (Pump = @Pump OR @Pump IS NULL)
	AND EDISID = @EDISID
	AND ((ValidFrom <= @Date AND @ToDate IS NULL) OR ((@Date <= ValidTo AND @ToDate >= ValidFrom) OR (@ToDate >= ValidFrom AND ValidTo IS NULL)))
	AND (ValidTo >= @Date OR ValidTo IS NULL)
	AND (InUse = 1 OR @ShowNotInUse = 1)
	AND (IsWater = 0 OR @ShowWater = 1)
GROUP BY Pump, ProductID, LocationID, InUse, BarPosition, ValidFrom, ValidTo, Products.Description
	ORDER BY Pump
END



GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetHistoricalFont] TO PUBLIC
    AS [dbo];

