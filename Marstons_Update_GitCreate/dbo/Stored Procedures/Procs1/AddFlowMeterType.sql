---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE AddFlowMeterType
(
	@Description	VARCHAR(255),
	@ID		INT OUTPUT
)

AS

INSERT INTO dbo.FlowMeterTypes
([Description])
VALUES
(@Description)

SET @ID = @@IDENTITY


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddFlowMeterType] TO PUBLIC
    AS [dbo];

