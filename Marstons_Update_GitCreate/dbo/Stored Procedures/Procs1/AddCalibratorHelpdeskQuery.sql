CREATE PROCEDURE [dbo].[AddCalibratorHelpdeskQuery] 

	@DatabaseID INT,
	@EDISID INT,
	@TimeLogged DATETIME, 
	@LoggedBy AS VARCHAR(100),
	@IssueTypeID INT, 
	@ProblemDescription VARCHAR(1000)
AS
BEGIN

	SET NOCOUNT ON;
	
	DECLARE @MultipleAuditors BIT
	DECLARE @Auditor VARCHAR(50)
	
	SELECT	@MultipleAuditors = MultipleAuditors
	FROM [SQL1\SQL1].ServiceLogger.dbo.EDISDatabases
	WHERE [ID] = @DatabaseID
  
	DECLARE @DefaultCDA VARCHAR(50)
	SELECT @DefaultCDA = PropertyValue
	FROM Configuration
	WHERE PropertyName = 'AuditorName'
	
	SELECT @Auditor = CASE WHEN @MultipleAuditors = 1 THEN Sites.SiteUser ELSE 'MAINGROUP\' + REPLACE(@DefaultCDA, ' ', '.') END
	FROM Sites
	WHERE EDISID = @EDISID

	EXEC [EDISSQL1\SQL1].ServiceLogger.dbo.AddCalibratorHelpdeskQuery @DatabaseID, @EDISID, @TimeLogged, @LoggedBy, @IssueTypeID, @ProblemDescription, @Auditor

END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddCalibratorHelpdeskQuery] TO PUBLIC
    AS [dbo];

