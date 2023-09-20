CREATE PROCEDURE [dbo].[AddBillingItem]
(
	@Description				VARCHAR(255),
	@IsHHTAvailable				BIT = 1,
	@IsQuantityAvailable		BIT = 0,
	@BMSPartCost				MONEY = 0,
	@BMSRetailPrice				MONEY = 0,
	@IDraughtPartCost			MONEY = 0,
	@IDraughtRetailPrice		MONEY = 0,
	@BMSLabourBy5Minutes		INT = 0,
	@IDraughtLabourBy5Minutes	INT = 0,
	@NewID						INT OUTPUT,
	@Type						INT = 1,
	@LabourCharge				FLOAT = 0,
	@LabourTypeID				INT = 0,
	@CategoryID					INT = 0
)
AS

EXEC [EDISSQL1\SQL1].ServiceLogger.dbo.AddBillingItem @Description, @IsHHTAvailable, @IsQuantityAvailable, @BMSPartCost, @BMSRetailPrice, @IDraughtPartCost, @IDraughtRetailPrice, @BMSLabourBy5Minutes, @IDraughtLabourBy5Minutes, @NewID OUTPUT, @Type, @LabourCharge, @LabourTypeID, @CategoryID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddBillingItem] TO PUBLIC
    AS [dbo];

