CREATE PROCEDURE [dbo].[GetProposedFontSetupItemsByEDISID]
(
	@EDISID	INT
)

AS

SET NOCOUNT ON

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
	((NewCalibrationValue/OriginalCalibrationValue) * 100) as CalibrationValuePercentChange,
	DispenseEquipmentTypeID,		-- deprecated
	DispenseEquipmentType,
	CalibratedOnWater,
	DispenseProductType,
	CalibrationIssueType,
	Calibrated,
	CalibrationChangeType,
	Review, 
	ProposedFontSetups.CreateDate as CreateDate	
FROM ProposedFontSetupItems
INNER JOIN
	ProposedFontSetups ON ProposedFontSetups.ID = ProposedFontSetupItems.ProposedFontSetupID
WHERE
	ProposedFontSetups.EDISID = @EDISID

ORDER BY ProposedFontSetups.CreateDate desc


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetProposedFontSetupItemsByEDISID] TO PUBLIC
    AS [dbo];

