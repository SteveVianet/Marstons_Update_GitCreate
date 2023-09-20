CREATE PROCEDURE [dbo].[AddCallReason]
(
	@CallID			INT,
	@ReasonTypeID	INT,
	@AdditionalInfo	VARCHAR(512),
	@NewID			INT	OUTPUT,
	@AdditionalID	INT = NULL,
	@StartDate		DATETIME = NULL
)

AS

SET NOCOUNT ON
SET XACT_ABORT ON

DECLARE @ExcludeFromQuality BIT
DECLARE @ExcludeFromYield BIT
DECLARE @ExcludeFromEquipment BIT
DECLARE @ExcludeAllProducts	BIT

BEGIN TRAN

INSERT INTO dbo.CallReasons
(CallID, ReasonTypeID, AdditionalInfo)
VALUES
(@CallID, @ReasonTypeID, @AdditionalInfo)

SET @NewID = @@IDENTITY

SELECT	@ExcludeFromQuality = ExcludeFromQuality,
		@ExcludeFromYield = ExcludeFromYield,
		@ExcludeFromEquipment = ExcludeFromEquipment,
		@ExcludeAllProducts = ExcludeAllProducts
FROM [EDISSQL1\SQL1].ServiceLogger.dbo.CallReasonTypes
WHERE ID = @ReasonTypeID

IF @ExcludeFromQuality = 1
BEGIN
	EXEC dbo.AddServiceIssueQuality @CallID, @AdditionalID, @ExcludeAllProducts, @StartDate, @ReasonTypeID
END

IF @ExcludeFromYield = 1
BEGIN
	EXEC dbo.AddServiceIssueYield @CallID, @AdditionalID, @ExcludeAllProducts, @StartDate, @ReasonTypeID
END

IF @ExcludeFromEquipment = 1
BEGIN
	EXEC dbo.AddServiceIssueEquipment @CallID, @AdditionalID, @ExcludeAllProducts, @StartDate, @ReasonTypeID
END

--Refresh call on Handheld database if applicable
EXEC dbo.RefreshHandheldCall @CallID, 1, 0, 0

COMMIT

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddCallReason] TO PUBLIC
    AS [dbo];

