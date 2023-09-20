---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE ENG_PushEngineerJobComment
(
	@ReferenceID INT,
	@CallReference VARCHAR(20),
	@Comment VARCHAR(512),
	@Date DATETIME
)

AS

EXEC [SQL1\SQL1].ServiceLogger.dbo.ENG_PushEngineerJobComment	@ReferenceID,
								@CallReference,
								@Comment,
								@Date



GO
GRANT EXECUTE
    ON OBJECT::[dbo].[ENG_PushEngineerJobComment] TO PUBLIC
    AS [dbo];

