CREATE PROCEDURE [dbo].[UpdateCallTypeID]
(
	@CallID			INT,
	@TypeID			INT
)

AS

UPDATE dbo.Calls
SET CallTypeID = @TypeID
WHERE [ID] = @CallID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateCallTypeID] TO PUBLIC
    AS [dbo];

