CREATE PROCEDURE [dbo].[AddCallFault]
(
	@CallID INT,
	@FaultTypeID	INT,
	@AdditionalInfo	VARCHAR(255),
	@NewID	INT	OUTPUT,
	@SLA	INT = NULL
)

AS

SET XACT_ABORT ON

BEGIN TRAN

INSERT INTO dbo.CallFaults
(CallID, FaultTypeID, AdditionalInfo, SLA)
VALUES
(@CallID, @FaultTypeID, @AdditionalInfo, @SLA)

SET @NewID = @@IDENTITY

--Refresh call on Handheld database if applicable
EXEC dbo.RefreshHandheldCall @CallID, 1, 0, 0

COMMIT

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddCallFault] TO PUBLIC
    AS [dbo];

