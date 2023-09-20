---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE UpdateProposedFontSetup
(
	@ProposedFontSetupID	INT,
	@StockDelivered		BIT,
	@StockDay		SMALLINT,
	@LineCleanDay		SMALLINT,
	@DispenseDataCleared	BIT
)

AS

UPDATE ProposedFontSetups
SET	StockDelivered = @StockDelivered,
	StockDay = @StockDay,
	LineCleanDay = @LineCleanDay,
	DispenseDataCleared = @DispenseDataCleared
WHERE [ID] = @ProposedFontSetupID
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateProposedFontSetup] TO PUBLIC
    AS [dbo];

