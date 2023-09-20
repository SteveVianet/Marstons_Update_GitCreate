CREATE PROCEDURE [dbo].[GetWebSitePumpSetupIFMConfiguration]
(
	@EDISID		INT,
	@From			DATETIME,
	@To			DATETIME,
	@IncludeCasks		BIT,
	@IncludeKegs		BIT,
	@IncludeMetric		BIT,
	@Pump		INT = NULL
)
AS

SET NOCOUNT ON

DECLARE @Sites TABLE(EDISID INT NOT NULL, CellarID INT NOT NULL IDENTITY)
DECLARE @SitePumpCounts TABLE(Counter INT IDENTITY(1,1) PRIMARY KEY, EDISID INT NOT NULL, MaxPump INT NOT NULL)
DECLARE @SitePumpOffsets TABLE(EDISID INT NOT NULL PRIMARY KEY, PumpOffset INT NOT NULL)
 
DECLARE @AllSitePumps TABLE(EDISID INT NOT NULL, SitePump INT NOT NULL,
			    	 PumpID INT NOT NULL, LocationID INT NOT NULL, ProductID INT NOT NULL,
			    	 ValidFrom DATETIME NOT NULL, ValidTo DATETIME NOT NULL, IFMConfiguration VARCHAR(150) NULL)

DECLARE @SiteGroupID INT
DECLARE @SiteOnline DATETIME

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
WHERE (ValidFrom <= @To)
AND (ISNULL(ValidTo, @To) >= @From)
AND (ISNULL(ValidTo, @To) >= @SiteOnline)
GROUP BY PumpSetup.EDISID, Sites.CellarID
ORDER BY CellarID

INSERT INTO @SitePumpOffsets (EDISID, PumpOffset)
SELECT MainCounts.EDISID, COALESCE(QuaternaryCounts.MaxPump+TertiaryCounts.MaxPump+SecondaryCounts.MaxPump, TertiaryCounts.MaxPump+SecondaryCounts.MaxPump, 
SecondaryCounts.MaxPump, 0)
FROM @SitePumpCounts AS MainCounts
LEFT JOIN @SitePumpCounts AS SecondaryCounts ON SecondaryCounts.Counter+1 = MainCounts.Counter
LEFT JOIN @SitePumpCounts AS TertiaryCounts ON TertiaryCounts.Counter+2 = MainCounts.Counter
LEFT JOIN @SitePumpCounts AS QuaternaryCounts ON QuaternaryCounts.Counter+3 = MainCounts.Counter

INSERT INTO @AllSitePumps (EDISID, SitePump, PumpID, LocationID, ProductID, ValidFrom, ValidTo, IFMConfiguration)
SELECT	PumpSetup.EDISID, PumpSetup.Pump,
	PumpSetup.Pump+PumpOffset, PumpSetup.LocationID, PumpSetup.ProductID,
	PumpSetup.ValidFrom,
	ISNULL(PumpSetup.ValidTo, @To),
	PumpSetup.IFMConfiguration
FROM PumpSetup
JOIN @Sites AS Sites ON Sites.EDISID = PumpSetup.EDISID
JOIN @SitePumpOffsets AS SitePumpOffsets ON SitePumpOffsets.EDISID = PumpSetup.EDISID
WHERE (ValidFrom <= @To)
AND (ISNULL(ValidTo, @To) >= @From)
AND (ISNULL(ValidTo, @To) >= @SiteOnline)

SELECT	PumpSetup.EDISID,
		PumpSetup.PumpID AS Pump,
		PumpSetup.SitePump,
		Products.ID AS ProductID,
		Products.[Description] AS Product, 
        PumpSetup.LocationID, 
		Locations.[Description] AS Location,
		PumpSetup.ValidFrom,
		ISNULL(PumpSetup.ValidTo, @To) AS ValidTo,
		Products.IsCask,
		Products.IsMetric,
		PumpSetup.IFMConfiguration,
		LatestIFMAddressMaps.[Version]
FROM @AllSitePumps AS PumpSetup
JOIN Products ON Products.[ID] = PumpSetup.ProductID
JOIN Locations ON Locations.[ID] = PumpSetup.LocationID
LEFT JOIN (
		SELECT	LatestIFMAddresses.EDISID,
				ProposedFontSetupItems.FontNumber,
				ProposedFontSetupItems.[Version],
				ProposedFontSetupItems.ProposedFontSetupID
		FROM
		(
			SELECT  IFMAddressMaps.EDISID,
					IFMAddressMaps.FontNumber,
					MAX(IFMAddressMaps.ProposedFontSetupID) AS ProposedFontSetupID
			FROM
			(
				SELECT  ProposedFontSetupItems.PhysicalAddress,
						ProposedFontSetups.EDISID,
						ProposedFontSetupItems.FontNumber,
						ProposedFontSetups.ID AS ProposedFontSetupID,
						ProposedFontSetupItems.Version
				FROM ProposedFontSetupItems
				JOIN ProposedFontSetups ON ProposedFontSetups.ID = ProposedFontSetupItems.ProposedFontSetupID
				JOIN (
					SELECT PhysicalAddress, MAX(ProposedFontSetupID) AS ProposedFontSetupID
					FROM ProposedFontSetupItems
					WHERE PhysicalAddress BETWEEN 0xC8 AND 0xFFFFFF AND Version IS NOT NULL
					GROUP BY PhysicalAddress
				) AS LatestFontSetup ON (LatestFontSetup.ProposedFontSetupID = ProposedFontSetupItems.ProposedFontSetupID AND LatestFontSetup.PhysicalAddress = ProposedFontSetupItems.PhysicalAddress)
				WHERE ProposedFontSetupItems.PhysicalAddress BETWEEN 0xC8 AND 0xFFFFFF
			) AS IFMAddressMaps
			GROUP BY IFMAddressMaps.EDISID, IFMAddressMaps.FontNumber
		) AS LatestIFMAddresses
		JOIN ProposedFontSetupItems ON ProposedFontSetupItems.ProposedFontSetupID = LatestIFMAddresses.ProposedFontSetupID AND ProposedFontSetupItems.FontNumber = LatestIFMAddresses.FontNumber
) AS LatestIFMAddressMaps ON LatestIFMAddressMaps.EDISID = PumpSetup.EDISID AND LatestIFMAddressMaps.FontNumber = PumpSetup.PumpID
WHERE (Products.IsCask = 0 OR @IncludeCasks = 1)
AND (Products.IsCask = 1 OR @IncludeKegs = 1)
AND (Products.IsMetric = 0 OR @IncludeMetric = 1)
AND Products.IsWater = 0
AND ((PumpSetup.SitePump = @Pump AND PumpSetup.EDISID = @EDISID) OR @Pump IS NULL)

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetWebSitePumpSetupIFMConfiguration] TO PUBLIC
    AS [dbo];

