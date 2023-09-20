---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE AddCoordinatorArea
(
	@CoordinatorID	INT,
	@PostcodeAreaID	INT,
	@DistrictFrom	INT,
	@DistrictTo	INT	
)

AS

DECLARE @NewAreaID	INT

EXEC @NewAreaID = [SQL1\SQL1].ServiceLogger.dbo.AddCoordinatorArea @CoordinatorID,
								       @PostcodeAreaID,
								       @DistrictFrom,
								       @DistrictTo

RETURN @NewAreaID



GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddCoordinatorArea] TO PUBLIC
    AS [dbo];

