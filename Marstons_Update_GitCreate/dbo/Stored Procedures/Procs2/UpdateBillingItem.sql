CREATE PROCEDURE [dbo].[UpdateBillingItem]
(
	@ID							INTEGER,
	@Description				VARCHAR(255),
	@IsHHTAvailable				BIT,
	@IsQuantityAvailable		BIT,
	@BMSPartCost				MONEY,
	@BMSRetailPrice				MONEY,
	@IDraughtPartCost			MONEY,
	@IDraughtRetailPrice		MONEY,
	@BMSLabourBy5Minutes		FLOAT,
	@IDraughtLabourBy5Minutes	FLOAT,
	@Type						INTEGER = 1,
	@LabourCharge				FLOAT = 0,
	@LabourTypeID				INT = 0,
	@CategoryID					INT = 0
)
AS

EXEC [EDISSQL1\SQL1].ServiceLogger.dbo.UpdateBillingItem @ID, @Description, @IsHHTAvailable, @IsQuantityAvailable, @BMSPartCost, @BMSRetailPrice, @IDraughtPartCost, @IDraughtRetailPrice, @BMSLabourBy5Minutes, @IDraughtLabourBy5Minutes, @Type, @LabourCharge, @LabourTypeID, @CategoryID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateBillingItem] TO PUBLIC
    AS [dbo];

