---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE [dbo].[AddCallAction]
(
	@CallID		INT,
	@ActionID	INT,
	@ActionText	VARCHAR(2000),
	@NewCallActionID	INT OUTPUT,
	@ActionUser	VARCHAR(255) = NULL,
	@ActionTime DATETIME = NULL
)

AS

IF (@ActionUser IS NOT NULL) AND (@ActionTime IS NOT NULL)
BEGIN
	INSERT INTO CallActions
		(CallID, ActionID, ActionText, ActionUser, ActionTime)
	VALUES
		(@CallID, @ActionID, @ActionText, @ActionUser, @ActionTime)

	SET @NewCallActionID = @@IDENTITY
END

ELSE

BEGIN
	INSERT INTO CallActions
		(CallID, ActionID, ActionText)
	VALUES
		(@CallID, @ActionID, @ActionText)

	SET @NewCallActionID = @@IDENTITY
END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddCallAction] TO PUBLIC
    AS [dbo];

