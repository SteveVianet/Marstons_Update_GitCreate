CREATE PROCEDURE [dbo].[UpdateCallLabourCharges]
(
	@CallID					INT,
	@StandardLabourCharge	MONEY,
	@AdditionalLabourCharge	MONEY
)

AS

UPDATE dbo.Calls
SET StandardLabourCharge = @StandardLabourCharge,
	AdditionalLabourCharge = @AdditionalLabourCharge
WHERE [ID] = @CallID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateCallLabourCharges] TO PUBLIC
    AS [dbo];

