
CREATE PROCEDURE [dbo].[GetHistoricalFontWithMeter]
(
	@EDISID		INTEGER,
	@Pump		INTEGER = NULL,
	@Date		DATETIME
)

AS

SET NOCOUNT ON


DECLARE @SiteOnline DATETIME
DECLARE @PreviousPFS INT

DECLARE @MaxPulseMeterAddress INT = 399

SELECT @SiteOnline = SiteOnline
FROM dbo.Sites
WHERE EDISID = @EDISID

SELECT @PreviousPFS = MAX(PFS.ID)
FROM ProposedFontSetups AS PFS
WHERE PFS.EDISID = @EDISID
AND CAST(CreateDate AS DATE) <= @Date

DECLARE @IFMs TABLE ([Pump] INT NOT NULL)
INSERT INTO @IFMs ([Pump])
SELECT
    PFSI.FontNumber
FROM ProposedFontSetups AS PFS
LEFT JOIN ProposedFontSetupItems AS PFSI ON PFS.ID = PFSI.ProposedFontSetupID
WHERE PFS.EDISID = @EDISID
AND PFS.ID = @PreviousPFS
AND PFSI.PhysicalAddress > @MaxPulseMeterAddress
AND (@Pump Is NULL OR PFSI.FontNumber = @Pump)

SELECT DISTINCT
    PumpSetup.Pump,
	ProductID,
	LocationID,
	InUse,
	BarPosition,
	ValidFrom,
	ValidTo,
	Products.[Description],
    CAST(CASE WHEN IFMs.Pump IS NULL THEN 0 ELSE 1 END AS BIT) AS IsIFM
FROM dbo.PumpSetup JOIN dbo.Products ON dbo.PumpSetup.ProductID = dbo.Products.ID
LEFT JOIN @IFMs AS IFMs ON dbo.PumpSetup.Pump = IFMs.Pump
WHERE (PumpSetup.Pump = @Pump OR @Pump IS NULL)
AND EDISID = @EDISID
AND ((ValidFrom <= @Date) OR ((@Date <= ValidTo) OR (ValidTo IS NULL)))
AND (ValidTo >= @Date OR ValidTo IS NULL)
ORDER BY PumpSetup.Pump

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetHistoricalFontWithMeter] TO PUBLIC
    AS [dbo];


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetHistoricalFontWithMeter] TO [fusion]
    AS [dbo];

