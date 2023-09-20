---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE UpdateCoordinatorArea
(
	@AreaID		INT,
	@CoordinatorID	INT,
	@PostcodeAreaID	INT,
	@DistrictFrom	INT,
	@DistrictTo	INT	
)

AS

EXEC [SQL1\SQL1].ServiceLogger.dbo.UpdateCoordinatorArea @AreaID,
							     @CoordinatorID,
							     @PostcodeAreaID,
							     @DistrictFrom,
							     @DistrictTo



GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateCoordinatorArea] TO PUBLIC
    AS [dbo];

