CREATE PROCEDURE dbo.GetSystemPowerOff 


	@From DATETIME,
	@To DATETIME
	
AS
BEGIN
    
	SET NOCOUNT ON;
	
	DECLARE @PowerOffCount TABLE (Customer VARCHAR (50),
								  SiteID VARCHAR (50),
								  SiteName VARCHAR (50),
								  Postcode VARCHAR (10),
								  PowerOffs INT,
								  AssignedCDA VARCHAR (50))
								  
	
	DECLARE @DefaultCDA VARCHAR(50)
	SELECT @DefaultCDA = PropertyValue
	FROM Configuration
	WHERE PropertyName = 'AuditorName'
	
	DECLARE @MultipleAuditors BIT
	SELECT @MultipleAuditors = MultipleAuditors 
	FROM [SQL1\SQL1].ServiceLogger.dbo.EDISDatabases
	WHERE Name = DB_NAME()
	AND (LimitToClient = HOST_NAME() OR LimitToClient IS NULL)
	
	
	INSERT INTO @PowerOffCount (Customer, SiteID, SiteName, Postcode, PowerOffs, AssignedCDA)
		
		SELECT Configuration.PropertyValue AS Customer,
			   SiteID, 
			   Name, 
			   PostCode,
			   OfflineCount.Result,
			   CASE WHEN @MultipleAuditors = 1 
				 THEN dbo.udfNiceName(Sites.SiteUser) 
				 ELSE dbo.udfNiceName(@DefaultCDA) 		
			   END 
		FROM Sites
		
		JOIN Configuration ON Configuration.PropertyName = 'Company Name'
		
		JOIN (SELECT EDISID, COUNT(*) AS Result
			  FROM dbo.FaultStack
		      JOIN MasterDates ON MasterDates.[ID] = FaultStack.FaultID
		      WHERE FaultStack.[Description] = 'Mains power failed' AND MasterDates.[Date] BETWEEN @From AND @To 
		      GROUP BY EDISID)
		      
		      AS OfflineCount ON OfflineCount.EDISID = Sites.EDISID
		      
		SELECT Customer, SiteID, SiteName, Postcode, PowerOffs, AssignedCDA
		FROM @PowerOffCount
    
END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSystemPowerOff] TO PUBLIC
    AS [dbo];

