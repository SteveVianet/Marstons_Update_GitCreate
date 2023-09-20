CREATE PROCEDURE [dbo].[UpdateProposedFontSetupItem]
(
	@ProposedFontSetupID		INT,
	@FontNumber				INT,
	@Product				VARCHAR(1024),
	@Location				VARCHAR(1024),
	@InUse				BIT,
	@JobType				INT = 0,
	@GlassID				NVARCHAR(50) = NULL,
	@Version				INT = NULL,
	@PhysicalAddress			INT = NULL,
	@StockValue				FLOAT = NULL,
	@NewCalibrationValue			INT = NULL,
	@OriginalCalibrationValue		INT = NULL,
	@DispenseEquipmentType		INT = 0,			-- deprecated
	@CalibratedOnWater			BIT = 0,
	@DispenseProductType		INT = 1,
	@CalibrationIssueType			INT = 1,
	@Calibrated				BIT = 0,
	@DispenseEquipmentTypeID		INT = 1,
	@CalibrationChangeType	INT = 1,
	@Review					BIT = 0
	
)

AS

-- Temporary workaround to catch any GlassID INT values which may be passed in with an old SiteLib
IF LEN(@GlassID)< 3
BEGIN
	SET @GlassID = NULL
END	

UPDATE ProposedFontSetupItems
SET	Product					= @Product,
	Location				= @Location,
	InUse					= @InUse,
	JobType				= @JobType,
	GlasswareID				= @GlassID,
	[Version]				= @Version,
	PhysicalAddress			= @PhysicalAddress,
	StockValue				= @StockValue,
	NewCalibrationValue			= @NewCalibrationValue,
	OriginalCalibrationValue		= @OriginalCalibrationValue,
	DispenseEquipmentTypeID		= @DispenseEquipmentType,
	CalibratedOnWater			= @CalibratedOnWater,
	DispenseProductType			= @DispenseProductType,
	CalibrationIssueType			= @CalibrationIssueType,
	Calibrated				= @Calibrated,
	DispenseEquipmentType		= @DispenseEquipmentTypeID,
	CalibrationChangeType		= @CalibrationChangeType,
	Review					= @Review
WHERE ProposedFontSetupID = @ProposedFontSetupID
AND FontNumber = @FontNumber

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateProposedFontSetupItem] TO PUBLIC
    AS [dbo];

