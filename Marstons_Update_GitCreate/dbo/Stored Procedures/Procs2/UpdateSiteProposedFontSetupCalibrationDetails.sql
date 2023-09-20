CREATE PROCEDURE [dbo].[UpdateSiteProposedFontSetupCalibrationDetails]
(
	@EDISID		INT = NULL,
	@ProposedFontSetupID	INT,
	@NewGlasswareStateID	INT OUTPUT
)

AS

DECLARE @CalResult TABLE(EDISID INT, GlasswareState INT)
DECLARE @ResultCount INT
DECLARE @CreateDate DATETIME
DECLARE @GlasswareStateID INT
DECLARE @ExistingGlasswareState INT
DECLARE @LatestSiteFontSetupID INT

SELECT @CreateDate = CreateDate, @EDISID = EDISID
FROM ProposedFontSetups
WHERE [ID] = @ProposedFontSetupID

SELECT @LatestSiteFontSetupID = MAX([ID])
FROM ProposedFontSetups
WHERE [EDISID] = @EDISID
GROUP BY [EDISID]

-- Get an overall calibration result (full-glass, key-glass, partial-glass or non-glass)
INSERT INTO @CalResult
(EDISID, GlasswareState)
-- Get an overall calibration result (full-glass, key-glass, partial-glass or non-glass)
SELECT  COALESCE(SitePumpCals.EDISID, Sites.EDISID) AS EDISID,
	CASE
	  WHEN SUM(Glass) = 0 OR SUM(Glass) IS NULL THEN 0
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
			WHERE JobType IN (1,2) AND GlasswareID IS NOT NULL AND ProposedFontSetups.CreateDate <= @CreateDate
			GROUP BY EDISID, FontNumber
		) AS GlassCals ON GlassCals.SetupID = PFS.ProposedFontSetupID AND GlassCals.FontNumber = PFS.FontNumber
	) AS GlassCalFonts ON GlassCalFonts.EDISID = PumpSetup.EDISID AND GlassCalFonts.Pump = PumpSetup.Pump
	WHERE ((@CreateDate BETWEEN ValidFrom AND ISNULL(ValidTo, @CreateDate) AND @LatestSiteFontSetupID <> @ProposedFontSetupID) OR ValidTo IS NULL)
	AND PumpSetup.InUse = 1
	AND Products.IsWater = 0
	AND Products.IsMetric = 0
	AND Sites.EDISID = @EDISID
) AS SitePumpCals ON SitePumpCals.EDISID = Sites.EDISID
WHERE Sites.EDISID = @EDISID
GROUP BY COALESCE(SitePumpCals.EDISID, Sites.EDISID)

SELECT @ResultCount = COUNT(*) 
FROM @CalResult

IF @ResultCount = 0
BEGIN
	INSERT INTO @CalResult
	(EDISID, GlasswareState)
	VALUES
	(@EDISID, 0)
END

SELECT @GlasswareStateID = GlasswareState
FROM @CalResult

UPDATE ProposedFontSetups
SET GlasswareStateID = @GlasswareStateID
WHERE [ID] = @ProposedFontSetupID

SET @NewGlasswareStateID = @GlasswareStateID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateSiteProposedFontSetupCalibrationDetails] TO PUBLIC
    AS [dbo];

