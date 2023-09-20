
CREATE PROCEDURE [dbo].[UpdateOwner] 
(
	@OwnerID INT,
	@Name VARCHAR(255),
	@Address1 VARCHAR(255),
	@Address2 VARCHAR(255),
	@Address3 VARCHAR(255),
	@Address4 VARCHAR(255),
	@Postcode VARCHAR(9),
	@ContactName VARCHAR(255),
	@SendScorecardEmail BIT = 0,
	@POSYieldCashValue MONEY = 0,
	@CleaningCashValue MONEY = 0,
	@PouringYieldCashValue MONEY = 0,
	@TargetPouringYieldPercent INT = 0,
	@TargetTillYieldPercent INT = 0,
	@ScorecardFromEmailAddress VARCHAR(100) = NULL,
	@UseExceptionReporting BIT = 0,
	@AutoSendExceptions BIT = 0
)
AS

UPDATE dbo.Owners
SET	Name = @Name,
	Address1 = @Address1,
	Address2 = @Address2,
	Address3 = @Address3,
	Address4 = @Address4,
	Postcode = @Postcode,
	ContactName = @ContactName,
	SendScorecardEmail = @SendScorecardEmail,
	POSYieldCashValue = @POSYieldCashValue,
	CleaningCashValue = @CleaningCashValue,
	PouringYieldCashValue = @PouringYieldCashValue,
	TargetPouringYieldPercent = @TargetPouringYieldPercent,
	TargetTillYieldPercent = @TargetTillYieldPercent,
	ScorecardFromEmailAddress = @ScorecardFromEmailAddress,
	UseExceptionReporting = @UseExceptionReporting,
	AutoSendExceptions = @AutoSendExceptions
WHERE ID = @OwnerID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateOwner] TO PUBLIC
    AS [dbo];

