
CREATE PROCEDURE dbo.UpdateCalibratorJobRank
	
	@JobID AS INT,
	@Rank AS INT

AS
BEGIN
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	EXEC [EDISSQL1\SQL1].ServiceLogger.dbo.UpdateCalibratorJobRank @JobID, @Rank
END
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateCalibratorJobRank] TO PUBLIC
    AS [dbo];

