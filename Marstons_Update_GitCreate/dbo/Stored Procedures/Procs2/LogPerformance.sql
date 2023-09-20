CREATE PROCEDURE [dbo].[LogPerformance]

	-- Add the parameters for the stored procedure here
	@StoredProcedureName VARCHAR(100),
	@Parameters VARCHAR(255),
	@ParameterCount INT,
	@QueryTime FLOAT,
	@ComputerName VARCHAR(50),
	@UserName VARCHAR(50),
	@ApplicationName VARCHAR(50),
	@ApplicationVersion VARCHAR(50),
	@LibraryName VARCHAR(50),
	@LibraryVersion VARCHAR(50),
	@DatabaseName VARCHAR(50),
	@ServerName VARCHAR(50),
	@DateExecuted DATETIME,
	@AttemptsTaken INT,
	@QueryTimeoutPeriod FLOAT
	 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	EXEC [SQL1\SQL1].ServiceLogger.dbo.LogGlobalPerformance @StoredProcedureName, 
																@Parameters, 
																@ParameterCount,
																@QueryTime,
																@ComputerName,
																@UserName,
																@ApplicationName,
																@ApplicationVersion,
																@LibraryName,
																@LibraryVersion,
																@DatabaseName,
																@ServerName,
																@DateExecuted,
																@AttemptsTaken,
																@QueryTimeoutPeriod
																 
	
END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[LogPerformance] TO PUBLIC
    AS [dbo];

