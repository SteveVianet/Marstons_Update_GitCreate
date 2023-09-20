---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE [dbo].[InsertProposedFontSetup]
(
	@EDISID					INT,
	@CallID					INT,
	@UserName				VARCHAR(255),
	@CreateDate				DATETIME,
	@Completed				BIT,
	@Available				BIT,
	@StockDelivered			BIT,
	@StockDay				SMALLINT,
	@LineCleanDay			SMALLINT,
	@DispenseDataCleared	BIT,
	@Comment				TEXT,
	@Calibrator				VARCHAR(255),
	@FlowmetersUsed			INT,
	@TamperCapsUsed			INT,
	@PowerSupplyType		INT,
	@ID						INT OUT
)

AS

INSERT INTO ProposedFontSetups 
	(EDISID, CallID, UserName, CreateDate, Completed, Available, StockDelivered, StockDay, LineCleanDay, DispenseDataCleared, Comment, Calibrator, FlowmetersUsed, TamperCapsUsed, PowerSupplyType)
VALUES
	(@EDISID, @CallID, @UserName, @CreateDate, @Completed, @Available, @StockDelivered, @StockDay, @LineCleanDay, @DispenseDataCleared, @Comment, @Calibrator, @FlowmetersUsed, @TamperCapsUsed, @PowerSupplyType)
	
SELECT @ID = @@IDENTITY

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[InsertProposedFontSetup] TO PUBLIC
    AS [dbo];

