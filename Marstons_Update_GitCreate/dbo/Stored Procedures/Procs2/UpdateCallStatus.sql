CREATE PROCEDURE [dbo].[UpdateCallStatus]
(
	@CallID		INT,
	@StatusID	INT,
	@SubStatusID	INT	= -1
)

AS

SET XACT_ABORT ON

BEGIN TRAN

INSERT INTO CallStatusHistory (CallID, StatusID, SubStatusID)
VALUES (@CallID, @StatusID, @SubStatusID)

--Refresh call on Handheld database if applicable
EXEC dbo.RefreshHandheldCall @CallID, 1, 1, 1

COMMIT
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateCallStatus] TO PUBLIC
    AS [dbo];

