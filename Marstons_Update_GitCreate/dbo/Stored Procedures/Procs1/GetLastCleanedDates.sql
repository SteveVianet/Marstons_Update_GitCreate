CREATE PROCEDURE [dbo].[GetLastCleanedDates]
(
      @EDISID           INT,
      @LimitDate  DATETIME = NULL,
      @FromDate   DATETIME = NULL
)
AS
 
SET NOCOUNT ON
 
DECLARE @Sites TABLE(EDISID INT NOT NULL, CellarID INT NOT NULL IDENTITY)
DECLARE @SiteGroupID INT
DECLARE @SitePumpCounts TABLE(Counter INT IDENTITY(1,1) PRIMARY KEY, EDISID INT NOT NULL, MaxPump INT NOT NULL)
DECLARE @SitePumpOffsets TABLE(EDISID INT NOT NULL PRIMARY KEY, PumpOffset INT NOT NULL)
 
DECLARE @AllSitePumps TABLE(PumpID INT NOT NULL, LocationID INT NOT NULL, ProductID INT NOT NULL,
                                LongestCleanPeriod INT NOT NULL)
DECLARE @SiteOnline DATETIME
DECLARE @IsBQM BIT
DECLARE @MaxCleanPeriod INT
 
SELECT @IsBQM = Quality
FROM dbo.Sites
WHERE EDISID = @EDISID
 
SELECT @SiteOnline = SiteOnline
FROM dbo.Sites
WHERE EDISID = @EDISID
 
-- Find out which EDISIDs are relevant (plough through SiteGroups)
INSERT INTO @Sites
(EDISID)
SELECT EDISID
FROM Sites
WHERE EDISID = @EDISID
 
SELECT @SiteGroupID = SiteGroupID
FROM SiteGroupSites
JOIN SiteGroups ON SiteGroups.ID = SiteGroupSites.SiteGroupID
WHERE TypeID = 1 AND EDISID = @EDISID
 
INSERT INTO @Sites (EDISID)
SELECT SiteGroupSites.EDISID
FROM SiteGroupSites
JOIN Sites ON Sites.EDISID = SiteGroupSites.EDISID
WHERE SiteGroupSites.SiteGroupID = @SiteGroupID AND SiteGroupSites.EDISID <> @EDISID
 
-- Get pumps for secondary sites (note that 1st EDISID IN @Sites is primary site)
INSERT INTO @SitePumpCounts (EDISID, MaxPump)
SELECT PumpSetup.EDISID, MAX(Pump)
FROM PumpSetup
JOIN @Sites AS Sites ON Sites.EDISID = PumpSetup.EDISID
WHERE (ValidFrom <= @LimitDate)
AND (ISNULL(ValidTo, @LimitDate) >= @SiteOnline)
GROUP BY PumpSetup.EDISID, Sites.CellarID
ORDER BY CellarID
 
INSERT INTO @SitePumpOffsets (EDISID, PumpOffset)
SELECT MainCounts.EDISID, COALESCE(QuaternaryCounts.MaxPump+TertiaryCounts.MaxPump+SecondaryCounts.MaxPump, TertiaryCounts.MaxPump+SecondaryCounts.MaxPump, SecondaryCounts.MaxPump, 0)
FROM @SitePumpCounts AS MainCounts
LEFT JOIN @SitePumpCounts AS SecondaryCounts ON SecondaryCounts.Counter+1 = MainCounts.Counter
LEFT JOIN @SitePumpCounts AS TertiaryCounts ON TertiaryCounts.Counter+2 = MainCounts.Counter
LEFT JOIN @SitePumpCounts AS QuaternaryCounts ON QuaternaryCounts.Counter+3 = MainCounts.Counter
 
--SELECT * FROM @SitePumpOffsets
 
INSERT INTO @AllSitePumps (PumpID, LocationID, ProductID, LongestCleanPeriod)
SELECT Pump+PumpOffset, LocationID, PumpSetup.ProductID,
      Products.LineCleanDaysBeforeRed
FROM PumpSetup
JOIN @Sites AS Sites ON Sites.EDISID = PumpSetup.EDISID
JOIN @SitePumpOffsets AS SitePumpOffsets ON SitePumpOffsets.EDISID = PumpSetup.EDISID
JOIN Products ON Products.[ID] = PumpSetup.ProductID
LEFT JOIN SiteProductSpecifications ON Products.ID = SiteProductSpecifications.ProductID AND PumpSetup.EDISID = SiteProductSpecifications.EDISID
WHERE (ValidFrom <= @LimitDate)
AND (ISNULL(ValidTo, @LimitDate) >= @SiteOnline)
AND PumpSetup.InUse = 1
 
SELECT @MaxCleanPeriod = MAX(LongestCleanPeriod) FROM @AllSitePumps
 
--SELECT * FROM @AllSitePumps
 
DECLARE @LastCleanedTable TABLE(EDISID INT NOT NULL, Line INT, RealLine INT, LastCleaned DATETIME)
 
IF @IsBQM = 1
BEGIN
      IF @LimitDate IS NOT NULL
      BEGIN
            INSERT INTO @LastCleanedTable (EDISID, Line, RealLine, LastCleaned)
            SELECT MasterDates.EDISID, CleaningStack.Line + PumpOffset, CleaningStack.Line, MAX(MasterDates.[Date])
            FROM CleaningStack
            JOIN MasterDates ON MasterDates.ID = CleaningStack.CleaningID
            JOIN @SitePumpOffsets AS SitePumpOffsets ON SitePumpOffsets.EDISID = MasterDates.EDISID
            JOIN @AllSitePumps AS AllSitePumps ON AllSitePumps.PumpID = CleaningStack.Line + PumpOffset
            JOIN Sites ON Sites.EDISID = MasterDates.EDISID
            WHERE MasterDates.EDISID IN (SELECT EDISID FROM @Sites)
            AND MasterDates.[Date] >= @SiteOnline
            AND MasterDates.[Date] <= @LimitDate
            GROUP BY MasterDates.EDISID, CleaningStack.Line + PumpOffset, CleaningStack.Line
      END
      ELSE
      BEGIN
            INSERT INTO @LastCleanedTable (EDISID, Line, RealLine, LastCleaned)
            SELECT MasterDates.EDISID, CleaningStack.Line + PumpOffset, CleaningStack.Line, MAX(MasterDates.[Date])
            FROM CleaningStack
            JOIN MasterDates ON MasterDates.ID = CleaningStack.CleaningID
            JOIN @SitePumpOffsets AS SitePumpOffsets ON SitePumpOffsets.EDISID = MasterDates.EDISID
            JOIN @AllSitePumps AS AllSitePumps ON AllSitePumps.PumpID = CleaningStack.Line + PumpOffset
            JOIN Sites ON Sites.EDISID = MasterDates.EDISID
            WHERE MasterDates.EDISID IN (SELECT EDISID FROM @Sites)
            AND MasterDates.[Date] >= @SiteOnline
            GROUP BY MasterDates.EDISID, CleaningStack.Line + PumpOffset, CleaningStack.Line
      END
END
ELSE
BEGIN
      IF @LimitDate IS NOT NULL
      BEGIN
            INSERT INTO @LastCleanedTable (EDISID, Line, RealLine, LastCleaned)
            SELECT MasterDates.EDISID, WaterStack.Line + PumpOffset, WaterStack.Line, MAX(MasterDates.[Date])
            FROM WaterStack
            JOIN MasterDates ON MasterDates.ID = WaterStack.WaterID
            JOIN @SitePumpOffsets AS SitePumpOffsets ON SitePumpOffsets.EDISID = MasterDates.EDISID
            JOIN @AllSitePumps AS AllSitePumps ON AllSitePumps.PumpID = WaterStack.Line + PumpOffset
            JOIN Sites ON Sites.EDISID = MasterDates.EDISID
            WHERE MasterDates.EDISID IN (SELECT EDISID FROM @Sites)
            AND MasterDates.[Date] >= @SiteOnline
            AND MasterDates.[Date] >= DATEADD(day, -@MaxCleanPeriod, ISNULL(@FromDate, @SiteOnline))
            AND MasterDates.[Date] <= @LimitDate
            GROUP BY MasterDates.EDISID, WaterStack.Line + PumpOffset, WaterStack.Line
      END
      ELSE
      BEGIN
            INSERT INTO @LastCleanedTable (EDISID, Line, RealLine, LastCleaned)
            SELECT MasterDates.EDISID, WaterStack.Line + PumpOffset, WaterStack.Line, MAX(MasterDates.[Date])
            FROM WaterStack
            JOIN MasterDates ON MasterDates.ID = WaterStack.WaterID
            JOIN @SitePumpOffsets AS SitePumpOffsets ON SitePumpOffsets.EDISID = MasterDates.EDISID
            JOIN @AllSitePumps AS AllSitePumps ON AllSitePumps.PumpID = WaterStack.Line + PumpOffset
            JOIN Sites ON Sites.EDISID = MasterDates.EDISID
            WHERE MasterDates.EDISID IN (SELECT EDISID FROM @Sites)
            AND MasterDates.[Date] >= @SiteOnline
            AND MasterDates.[Date] >= DATEADD(day, -@MaxCleanPeriod, ISNULL(@FromDate, @SiteOnline))
            GROUP BY MasterDates.EDISID, WaterStack.Line + PumpOffset, WaterStack.Line
      END
END
 
SELECT EDISID, Line, RealLine, LastCleaned FROM @LastCleanedTable
 

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetLastCleanedDates] TO PUBLIC
    AS [dbo];

