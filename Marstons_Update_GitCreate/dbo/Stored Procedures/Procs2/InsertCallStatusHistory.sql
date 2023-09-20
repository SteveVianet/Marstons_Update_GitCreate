CREATE PROCEDURE [dbo].[InsertCallStatusHistory]
(
	@CallID		INT,
	@StatusID	INT,
	@SubStatusID	INT,
	@ChangedOn	DATETIME,
	@ChangedBy	VARCHAR(255)
)

AS

INSERT INTO CallStatusHistory
	(CallID, StatusID, SubStatusID, ChangedOn, ChangedBy)
VALUES
	(@CallID, @StatusID, @SubStatusID, @ChangedOn, @ChangedBy)

EXEC RefreshHandheldCall @CallID, 1, 1, 1
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[InsertCallStatusHistory] TO PUBLIC
    AS [dbo];

