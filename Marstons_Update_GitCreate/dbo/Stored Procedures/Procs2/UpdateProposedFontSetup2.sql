CREATE PROCEDURE UpdateProposedFontSetup2
(
	@ProposedFontSetupID	INT,
	@StockDelivered		BIT,
	@StockDay			SMALLINT,
	@LineCleanDay		SMALLINT,
	@DispenseDataCleared	BIT,
	@CallID			INT = NULL,
	@Calibrator			VARCHAR(255),
	@FlowmetersUsed		INT,
	@TamperCapsUsed		INT,
	@PowerSupplyType		INT = 0,
	@CAMEngineerID		INT = NULL
)

AS

UPDATE dbo.ProposedFontSetups
SET	StockDelivered = @StockDelivered,
	StockDay = @StockDay,
	LineCleanDay = @LineCleanDay,
	DispenseDataCleared = @DispenseDataCleared,
	CallID = @CallID,
	Calibrator = @Calibrator,
	FlowmetersUsed = @FlowmetersUsed,
	TamperCapsUsed = @TamperCapsUsed,
	PowerSupplyType = @PowerSupplyType,
	CAMEngineerID = @CAMEngineerID
WHERE [ID] = @ProposedFontSetupID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateProposedFontSetup2] TO PUBLIC
    AS [dbo];

