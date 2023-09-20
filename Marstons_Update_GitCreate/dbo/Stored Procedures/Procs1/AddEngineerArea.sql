---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE AddEngineerArea
(
	@EngineerID	INT,
	@PostcodeAreaID	INT,
	@DistrictFrom	INT,
	@DistrictTo	INT,
	@Priority	INT
)

AS

DECLARE @NewAreaID	INT

EXEC @NewAreaID = [SQL1\SQL1].ServiceLogger.dbo.AddEngineerArea @EngineerID,
								    @PostcodeAreaID,
								    @DistrictFrom,
								    @DistrictTo,
								    @Priority

RETURN @NewAreaID



GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddEngineerArea] TO PUBLIC
    AS [dbo];

