CREATE PROCEDURE [dbo].[GetCalibrationDetails]
(
	@ScheduleName	VARCHAR(255) = NULL
)

AS

SET NOCOUNT ON
SET ANSI_WARNINGS OFF

DECLARE @Glass TABLE ([ID] INT NOT NULL, [Desc] VARCHAR(20) NOT NULL)

INSERT INTO @Glass ([ID], [Desc]) VALUES (0, 'No')
INSERT INTO @Glass ([ID], [Desc]) VALUES (1, 'Yes')
INSERT INTO @Glass ([ID], [Desc]) VALUES (2, 'Partial')
INSERT INTO @Glass ([ID], [Desc]) VALUES (3, 'Key products')

SELECT  Configuration2.PropertyValue AS DatabaseID,
	REPLACE(Configuration.PropertyValue, ',', ' ') AS CompanyName,
	REPLACE(Sites.Name, ',', ' ') AS SiteName,
	Sites.PostCode,
	Sites.SiteID,
	Glass.[Desc] AS GlasswareState,
	OldGlass.[Desc] AS OldGlasswareState,
	LastVisits.LastVisit,
	DATEADD(year, 1, LastVisits.LastVisit) AS DueDate,
	CASE WHEN LastVisitIsCall.CallID IS NULL THEN 'No' ELSE 'Yes' END AS LastVisitIsServiceCall,
	LastVisits2008.LastVisit AS Last2008,
	ISNULL(LastVisits2008.NumOfVisits,0) AS Num2008,
	LastVisits2009.LastVisit AS Last2009,
	ISNULL(LastVisits2009.NumOfVisits,0) AS Num2009,
	LastVisits2010.LastVisit AS Last2010,
	ISNULL(LastVisits2010.NumOfVisits,0) AS Num2010,
	Sites.SiteClosed
FROM Sites
JOIN (
	-- Get all sites and an overall calibration result (full-glass, key-glass, partial-glass or non-glass)
	SELECT Sites.EDISID, ISNULL(ProposedFontSetups.GlasswareStateID, 0) AS GlasswareStateID
	FROM Sites
	LEFT JOIN (SELECT EDISID, MAX(CreateDate) AS CreateDate 
				FROM ProposedFontSetups
				WHERE Available = 1
				GROUP BY EDISID) AS LastGlassware ON LastGlassware.EDISID = Sites.EDISID
	LEFT JOIN ProposedFontSetups ON ProposedFontSetups.EDISID = LastGlassware.EDISID AND
	                                ProposedFontSetups.CreateDate = LastGlassware.CreateDate
	WHERE Sites.Hidden = 0
	AND ( Sites.EDISID IN (
		SELECT EDISID
		FROM ScheduleSites
		JOIN Schedules ON Schedules.ID = ScheduleSites.ScheduleID
		WHERE Schedules.Description = @ScheduleName)
	OR @ScheduleName IS NULL )
) AS GlassOverview ON GlassOverview.EDISID = Sites.EDISID
JOIN @Glass AS Glass ON Glass.ID = GlassOverview.GlasswareStateID
JOIN Configuration ON Configuration.PropertyName = 'Company Name'
JOIN Configuration AS Configuration2 ON Configuration2.PropertyName = 'Service Owner ID'
LEFT JOIN (
	SELECT ProposedFontSetups.EDISID, MAX(CreateDate) AS LastVisit
	FROM ProposedFontSetups
	JOIN ProposedFontSetupItems ON ProposedFontSetupItems.ProposedFontSetupID = ProposedFontSetups.ID
	JOIN Sites ON Sites.EDISID = ProposedFontSetups.EDISID
	WHERE JobType IN (1,2) AND Sites.Hidden = 0
	GROUP BY ProposedFontSetups.EDISID
) AS LastVisits ON LastVisits.EDISID = Sites.EDISID
LEFT JOIN (
	SELECT EDISID, CallID, CreateDate
	FROM ProposedFontSetups
) AS LastVisitIsCall ON LastVisitIsCall.CreateDate = LastVisits.LastVisit AND LastVisitIsCall.EDISID = LastVisits.EDISID
LEFT JOIN (
	SELECT Calls.EDISID, MAX(VisitedOn) AS LastVisit, COUNT(*) AS NumOfVisits
	FROM Calls
	JOIN Sites ON Sites.EDISID = Calls.EDISID
	WHERE Sites.Hidden = 0 AND YEAR(VisitedOn) = 2008
	GROUP BY Calls.EDISID
) AS LastVisits2008 ON LastVisits2008.EDISID = Sites.EDISID
LEFT JOIN (
	SELECT Calls.EDISID, MAX(VisitedOn) AS LastVisit, COUNT(*) AS NumOfVisits
	FROM Calls
	JOIN Sites ON Sites.EDISID = Calls.EDISID
	WHERE Sites.Hidden = 0 AND YEAR(VisitedOn) = 2009
	GROUP BY Calls.EDISID
) AS LastVisits2009 ON LastVisits2009.EDISID = Sites.EDISID
LEFT JOIN (
	SELECT Calls.EDISID, MAX(VisitedOn) AS LastVisit, COUNT(*) AS NumOfVisits
	FROM Calls
	JOIN Sites ON Sites.EDISID = Calls.EDISID
	WHERE Sites.Hidden = 0 AND YEAR(VisitedOn) = 2010
	GROUP BY Calls.EDISID
) AS LastVisits2010 ON LastVisits2010.EDISID = Sites.EDISID
JOIN (
	SELECT  COALESCE(SitePumpCals.EDISID, Sites.EDISID) AS EDISID,
		CASE
		  WHEN SUM(Glass) = 0 THEN 0
		  WHEN SUM(Glass) = COUNT(Pump) THEN 1
		  WHEN SUM(KeyGlass) >= SUM(KeyProduct) THEN 3
		  ELSE 2
		  END AS GlasswareState
	FROM Sites
	FULL JOIN (
		-- Get all known flowmeters, if they are calibrated on glassware, a key producd, and a key product calibrated on glassware
		SELECT  PumpSetup.EDISID,
			PumpSetup.Pump,
			CASE WHEN GlassCalFonts.Pump IS NULL THEN 0 ELSE 1 END AS Glass,
			CASE WHEN SiteKeyProducts.ProductID IS NULL THEN 0 ELSE 1 END AS KeyProduct,
			CASE WHEN (GlassCalFonts.Pump IS NOT NULL) AND (SiteKeyProducts.ProductID IS NOT NULL) THEN 1 ELSE 0 END AS KeyGlass
		FROM PumpSetup
		JOIN Sites ON Sites.EDISID = PumpSetup.EDISID
		JOIN Products ON Products.ID = PumpSetup.ProductID
		FULL JOIN SiteKeyProducts ON SiteKeyProducts.ProductID = Products.ID AND SiteKeyProducts.EDISID = PumpSetup.EDISID
		FULL JOIN (
			-- Get all glassware-calibrated sites and flowmeters
			SELECT EDISID, PFS.FontNumber AS Pump
			FROM ProposedFontSetupItems AS PFS
			JOIN (	SELECT EDISID, FontNumber, MAX(ProposedFontSetupID) AS SetupID
				FROM ProposedFontSetupItems
				JOIN ProposedFontSetups ON ProposedFontSetups.ID = ProposedFontSetupItems.ProposedFontSetupID
				WHERE JobType IN (1,2) AND GlasswareID IS NOT NULL AND Calibrated = 1
				GROUP BY EDISID, FontNumber
			) AS GlassCals ON GlassCals.SetupID = PFS.ProposedFontSetupID AND GlassCals.FontNumber = PFS.FontNumber
		) AS GlassCalFonts ON GlassCalFonts.EDISID = PumpSetup.EDISID AND GlassCalFonts.Pump = PumpSetup.Pump
		WHERE PumpSetup.ValidTo IS NULL
		AND PumpSetup.InUse = 1
		AND Products.IsWater = 0
		AND Products.IsMetric = 0
	) AS SitePumpCals ON SitePumpCals.EDISID = Sites.EDISID
	GROUP BY COALESCE(SitePumpCals.EDISID, Sites.EDISID)
) AS OldMethod ON OldMethod.EDISID = Sites.EDISID
JOIN @Glass AS OldGlass ON OldGlass.ID = OldMethod.GlasswareState
ORDER BY Sites.EDISID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetCalibrationDetails] TO PUBLIC
    AS [dbo];

