CREATE PROCEDURE [dbo].[AddProposedFontSetupItem]
(
	@ProposedFontSetupID		INT,
	@FontNumber					INT,
	@Product					VARCHAR(1024),
	@Location					VARCHAR(1024),
	@InUse						BIT,
	@JobType					INT = 0,
	@GlassID					INT = NULL,
	@Version					INT = NULL,
	@PhysicalAddress			INT = NULL,
	@StockValue					FLOAT = NULL,
	@NewCalibrationValue		INT = NULL,
	@OriginalCalibrationValue	INT = NULL,
	@DispenseEquipmentTypeID	INT = 0,
	@CalibratedOnWater			BIT = 0,
	@GlasswareID				VARCHAR(50) = NULL,
    @LocationID                 INT = NULL,              -- If supplied, @Location is ignored
	@FailureReason				INT = 1,
--this down are added from the update sp
	@Calibrated				BIT = 0,
	@CalibrationChangeType	INT = 1,
	@Review					BIT = 0
)

AS

PRINT(@ProposedFontSetupID)
IF @LocationID IS NOT NULL
BEGIN
    SELECT @Location = [Description]
    FROM [Locations]
    WHERE [ID] = @LocationID
END

--IF (@DispenseEquipmentTypeID IS NOT NULL AND 
--@CalibratedOnWater IS NOT NULL)
--BEGIN

PRINT('Inserting proposedfontsetupitem to db')
	INSERT INTO ProposedFontSetupItems
		(ProposedFontSetupID, FontNumber, Product, Location, InUse, JobType, [Version], PhysicalAddress, StockValue, NewCalibrationValue, OriginalCalibrationValue, 
		DispenseEquipmentTypeID, CalibratedOnWater, GlasswareID, CalibrationIssueType,Calibrated,CalibrationChangeType,Review)
	VALUES
		(@ProposedFontSetupID, @FontNumber, @Product, @Location, @InUse, @JobType, @Version, @PhysicalAddress, @StockValue, @NewCalibrationValue, @OriginalCalibrationValue, 
		@DispenseEquipmentTypeID, @CalibratedOnWater, @GlasswareID, @FailureReason, @Calibrated, @CalibrationChangeType, @Review)
--END

--ELSE

--BEGIN
--	INSERT INTO ProposedFontSetupItems
--		(ProposedFontSetupID, FontNumber, Product, Location, InUse, JobType, [Version], PhysicalAddress, StockValue, NewCalibrationValue, OriginalCalibrationValue, DispenseEquipmentTypeID, CalibratedOnWater, GlasswareID, CalibrationIssueType)
--	VALUES
--		(@ProposedFontSetupID, @FontNumber, @Product, @Location, @InUse, @JobType, @Version, @PhysicalAddress, @StockValue, @NewCalibrationValue, @OriginalCalibrationValue, @DispenseEquipmentTypeID, @CalibratedOnWater, @GlasswareID, @FailureReason)
--END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddProposedFontSetupItem] TO PUBLIC
    AS [dbo];

