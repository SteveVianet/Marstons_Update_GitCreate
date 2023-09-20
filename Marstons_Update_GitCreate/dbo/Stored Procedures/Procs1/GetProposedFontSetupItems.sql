CREATE PROCEDURE [dbo].[GetProposedFontSetupItems]
(
	@ProposedFontSetupID	INT
)

AS

SET NOCOUNT ON

DECLARE @EDISID INT

SELECT @EDISID = EDISID
FROM ProposedFontSetups
WHERE [ID] = @ProposedFontSetupID

SELECT	ProposedFontSetupItems.FontNumber,
	Product,
	Location,
	InUse,
	JobType,
	GlasswareID,
	[Version],
	PhysicalAddress,
	StockValue,
	NewCalibrationValue,
	OriginalCalibrationValue,
	DispenseEquipmentTypeID,		-- deprecated
	DispenseEquipmentType,
	CalibratedOnWater,
	CAST(CASE WHEN GlassLines.LastGlassCal IS NULL THEN 0 ELSE 1 END AS BIT) AS CurrentlyCalibratedWithGlass,
	DispenseProductType,
	CalibrationIssueType,
	Calibrated,
	CalibrationChangeType,
	Review		
FROM ProposedFontSetupItems
LEFT OUTER JOIN (
	SELECT FontNumber, MAX(ProposedFontSetups.CreateDate) AS LastGlassCal
	FROM ProposedFontSetupItems
	JOIN ProposedFontSetups ON ProposedFontSetups.ID = ProposedFontSetupItems.ProposedFontSetupID
	WHERE ProposedFontSetups.EDISID = @EDISID
	AND GlasswareID IS NOT NULL
	AND JobType IN (1,2)
	AND [ID] < @ProposedFontSetupID
	GROUP BY FontNumber
) AS GlassLines ON GlassLines.FontNumber = ProposedFontSetupItems.FontNumber
WHERE ProposedFontSetupID = @ProposedFontSetupID
ORDER BY ProposedFontSetupItems.FontNumber



GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetProposedFontSetupItems] TO PUBLIC
    AS [dbo];

