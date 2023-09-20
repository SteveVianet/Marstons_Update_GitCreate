---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE AddCallTamper
(
	@CallID		INT,
	@ReasonID	INT,
	@Remarks	VARCHAR(255)
)

AS

INSERT INTO CallTampers
(CallID, ReasonID, Remarks)
VALUES
(@CallID, @ReasonID, @Remarks)


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddCallTamper] TO PUBLIC
    AS [dbo];

