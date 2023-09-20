---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE UpdateEngineerArea
(
	@AreaID		INT,
	@EngineerID	INT,
	@PostcodeAreaID	INT,
	@DistrictFrom	INT,
	@DistrictTo	INT,
	@Priority	INT	
)

AS

EXEC [SQL1\SQL1].ServiceLogger.dbo.UpdateEngineerArea @AreaID,
							  @EngineerID,
							  @PostcodeAreaID,
							  @DistrictFrom,
							  @DistrictTo,
							  @Priority


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateEngineerArea] TO PUBLIC
    AS [dbo];

