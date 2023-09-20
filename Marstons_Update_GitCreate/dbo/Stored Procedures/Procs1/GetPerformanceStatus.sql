CREATE PROCEDURE dbo.GetPerformanceStatus 
	-- Add the parameters for the stored procedure here
	@DatabaseID INT,
	@LogPerformance BIT OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT @LogPerformance = LogPerformance
	FROM [SQL1\SQL1].ServiceLogger.dbo.EDISDatabases
	WHERE ID = @DatabaseID
	
END
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetPerformanceStatus] TO PUBLIC
    AS [dbo];

