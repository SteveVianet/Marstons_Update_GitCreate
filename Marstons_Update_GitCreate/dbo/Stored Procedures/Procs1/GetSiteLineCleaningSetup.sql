
CREATE PROCEDURE [dbo].[GetSiteLineCleaningSetup]
(
	@EDISID	INT,
	@From		DATETIME,
	@To		DATETIME,
	@IncludeNIU BIT = 0
)
AS
SET NOCOUNT ON

DECLARE @Sites TABLE(EDISID INT NOT NULL, CellarID INT NOT NULL IDENTITY)
DECLARE @SitePumpCounts TABLE(Counter INT IDENTITY(1,1) PRIMARY KEY, EDISID INT NOT NULL, MaxPump INT NOT NULL)
DECLARE @SitePumpOffsets TABLE(EDISID INT NOT NULL PRIMARY KEY, PumpOffset INT NOT NULL)
DECLARE @PreviousCleans TABLE(EDISID INT NOT NULL, Pump INT NOT NULL, ProductID INT NOT NULL, LocationID INT NOT NULL, Cleaned DATETIME NOT NULL)
 
DECLARE @AllSitePumps TABLE(EDISID INT NOT NULL, SitePump INT NOT NULL,
			    	 PumpID INT NOT NULL, LocationID INT NOT NULL, ProductID INT NOT NULL,
			    	 ValidFrom DATETIME NOT NULL, ValidTo DATETIME NOT NULL,
                            	    	 DaysBeforeAmber INT NOT NULL, DaysBeforeRed INT NOT NULL,  PreviousClean DATETIME NOT NULL)

DECLARE @SiteGroupID INT
DECLARE @SiteOnline DATETIME
DECLARE @IsBQM BIT

SELECT @SiteOnline = SiteOnline, @IsBQM = Quality
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
WHERE (ValidFrom <= @To)
AND (ISNULL(ValidTo, @To) >= @From)
AND (ISNULL(ValidTo, @To) >= @SiteOnline)
GROUP BY PumpSetup.EDISID, Sites.CellarID
ORDER BY CellarID

INSERT INTO @SitePumpOffsets (EDISID, PumpOffset)
SELECT MainCounts.EDISID, COALESCE(QuaternaryCounts.MaxPump+TertiaryCounts.MaxPump+SecondaryCounts.MaxPump, TertiaryCounts.MaxPump+SecondaryCounts.MaxPump, SecondaryCounts.MaxPump, 0)
FROM @SitePumpCounts AS MainCounts
LEFT JOIN @SitePumpCounts AS SecondaryCounts ON SecondaryCounts.Counter+1 = MainCounts.Counter
LEFT JOIN @SitePumpCounts AS TertiaryCounts ON TertiaryCounts.Counter+2 = MainCounts.Counter
LEFT JOIN @SitePumpCounts AS QuaternaryCounts ON QuaternaryCounts.Counter+3 = MainCounts.Counter

IF @IsBQM = 1
BEGIN
	INSERT INTO @PreviousCleans
	(EDISID, Pump, ProductID, LocationID, Cleaned)
	SELECT MasterDates.EDISID,
	 	 PumpSetup.Pump,
	 	 PumpSetup.ProductID,
	 	 PumpSetup.LocationID,
		 MAX(MasterDates.[Date])
	FROM CleaningStack
	JOIN MasterDates ON MasterDates.ID = CleaningStack.CleaningID
	JOIN PumpSetup ON MasterDates.EDISID = PumpSetup.EDISID
			AND CleaningStack.Line = PumpSetup.Pump
	             		AND MasterDates.[Date] >= PumpSetup.ValidFrom
			AND (MasterDates.[Date] <= PumpSetup.ValidTo OR PumpSetup.ValidTo IS NULL)
	WHERE MasterDates.EDISID IN (SELECT EDISID FROM @Sites)
	AND MasterDates.[Date] <= @From
	GROUP BY MasterDates.EDISID,
		      PumpSetup.Pump,
		      PumpSetup.ProductID,
		      PumpSetup.LocationID
END
ELSE
BEGIN
	INSERT INTO @PreviousCleans
	(EDISID, Pump, ProductID, LocationID, Cleaned)
	SELECT MasterDates.EDISID,
	 	 PumpSetup.Pump,
	 	 PumpSetup.ProductID,
	 	 PumpSetup.LocationID,
		 MAX(MasterDates.[Date])
	FROM WaterStack
	JOIN MasterDates ON MasterDates.ID = WaterStack.WaterID
	JOIN PumpSetup ON MasterDates.EDISID = PumpSetup.EDISID
			AND WaterStack.Line = PumpSetup.Pump
	             		AND MasterDates.[Date] >= PumpSetup.ValidFrom
			AND (MasterDates.[Date] <= PumpSetup.ValidTo OR PumpSetup.ValidTo IS NULL)
	WHERE MasterDates.EDISID IN (SELECT EDISID FROM @Sites)
	AND MasterDates.[Date] <= @From
	GROUP BY MasterDates.EDISID,
		      PumpSetup.Pump,
		      PumpSetup.ProductID,
		      PumpSetup.LocationID
	HAVING SUM(WaterStack.Volume) >= 4
END

INSERT INTO @AllSitePumps (EDISID, SitePump, PumpID, LocationID, ProductID, ValidFrom, ValidTo, DaysBeforeAmber, DaysBeforeRed, PreviousClean)
SELECT	PumpSetup.EDISID, PumpSetup.Pump,
	PumpSetup.Pump+PumpOffset, PumpSetup.LocationID, PumpSetup.ProductID,
	PumpSetup.ValidFrom,
	ISNULL(PumpSetup.ValidTo, @To),
	COALESCE(SiteProductSpecifications.CleanDaysBeforeAmber, SiteSpecifications.CleanDaysBeforeAmber, Products.LineCleanDaysBeforeAmber),
	COALESCE(SiteProductSpecifications.CleanDaysBeforeRed, SiteSpecifications.CleanDaysBeforeRed, Products.LineCleanDaysBeforeRed),
	ISNULL(PreviousCleans.Cleaned, 0) AS PreviousClean
FROM PumpSetup
JOIN @Sites AS Sites ON Sites.EDISID = PumpSetup.EDISID
JOIN @SitePumpOffsets AS SitePumpOffsets ON SitePumpOffsets.EDISID = PumpSetup.EDISID
JOIN Products ON Products.[ID] = PumpSetup.ProductID
LEFT JOIN SiteProductSpecifications ON SiteProductSpecifications.EDISID = PumpSetup.EDISID
				   AND SiteProductSpecifications.ProductID = PumpSetup.ProductID
LEFT JOIN SiteSpecifications ON Sites.EDISID = SiteSpecifications.EDISID
LEFT JOIN @PreviousCleans AS PreviousCleans ON PreviousCleans.EDISID = PumpSetup.EDISID 
        					          AND PreviousCleans.Pump = PumpSetup.Pump 
					          AND PreviousCleans.ProductID = PumpSetup.ProductID
					          AND PreviousCleans.LocationID = PumpSetup.LocationID
WHERE (ValidFrom <= @To)
AND (ISNULL(ValidTo, @To) >= @From)
AND (ISNULL(ValidTo, @To) >= @SiteOnline)
AND Products.IsWater = 0
AND ((InUse = 1) OR (@IncludeNIU = 1))

SELECT	PumpSetup.EDISID,
		PumpSetup.PumpID AS Pump,
		PumpSetup.SitePump,
		Products.[Description] AS Product, 
        		PumpSetup.LocationID, 
		Locations.[Description] AS Location,
		PumpSetup.ValidFrom,
		ISNULL(PumpSetup.ValidTo, @To) AS ValidTo,
		PumpSetup.DaysBeforeAmber,
		PumpSetup.DaysBeforeRed,
		PumpSetup.PreviousClean
FROM @AllSitePumps AS PumpSetup
JOIN Products ON Products.[ID] = PumpSetup.ProductID
JOIN Locations ON Locations.[ID] = PumpSetup.LocationID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSiteLineCleaningSetup] TO PUBLIC
    AS [dbo];

