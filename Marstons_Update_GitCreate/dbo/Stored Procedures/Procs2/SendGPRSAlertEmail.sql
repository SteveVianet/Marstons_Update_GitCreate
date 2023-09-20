CREATE PROCEDURE [dbo].[SendGPRSAlertEmail]

AS

BEGIN

	SET NOCOUNT ON;

	DECLARE @DefaultCDA VARCHAR(50)
	SELECT @DefaultCDA = PropertyValue
	FROM Configuration
	WHERE PropertyName = 'AuditorName'

	DECLARE @MultipleAuditors BIT
	SELECT @MultipleAuditors = MultipleAuditors 
	FROM [SQL1\SQL1].ServiceLogger.dbo.EDISDatabases
	WHERE Name = DB_NAME()
	AND (LimitToClient = HOST_NAME() OR LimitToClient IS NULL)



	DECLARE @GPRSConnectionTable TABLE(CustomerName VARCHAR (50),
								  SiteID VARCHAR(15), 
								  EDISID INT,	
								  PubName VARCHAR(60), 
								  SiteUser VARCHAR (255), 
								  PropertyValue DATETIME,
								  DefaultEmailAddress VARCHAR (50))
								

			
	INSERT INTO @GPRSConnectionTable (CustomerName, SiteID, EDISID, PubName, SiteUser, PropertyValue, DefaultEmailAddress)	
		SELECT Configuration.PropertyValue AS CustomerName,
			   Sites.SiteID AS SiteID,
			   Sites.EDISID AS EDISID,
			   Sites.Name AS PubName,
			   Sites.SiteUser AS SiteUser, 
			   CONVERT(DATETIME, PropertyResults.Value) AS PropertyValue,
			   CASE WHEN @MultipleAuditors = 1 
				 THEN Sites.SiteUser 
				 ELSE @DefaultCDA 		
			   END
		FROM Sites WITH (NOLOCK)
		JOIN (
			SELECT  EDISID, PropertyID, Value, Properties.Name
			FROM SiteProperties 
			JOIN Properties ON Properties.ID = SiteProperties.PropertyID
			WHERE Properties.Name = 'Last GPRS connection'
			)AS PropertyResults ON PropertyResults.EDISID = Sites.EDISID	
			JOIN Configuration ON Configuration.PropertyName = 'Company Name'

	DECLARE curSendGPRSAlerts CURSOR FORWARD_ONLY READ_ONLY FOR	
		SELECT CustomerName, SiteID, EDISID, PubName, SiteUser, PropertyValue, REPLACE(LOWER(DefaultEmailAddress), 'maingroup\', '') + '@brulines.co.uk'
		FROM @GPRSConnectionTable
		WHERE PropertyValue > DateAdd(day, -2, GetDate()) AND  PropertyValue < DateAdd(day, -1, GetDate())
		ORDER BY PropertyValue ASC
		
	DECLARE @CustomerName VARCHAR(255)
	DECLARE @SiteID VARCHAR(15) 
	DECLARE @EDISID INT	
	DECLARE @PubName VARCHAR(60) 
	DECLARE @SiteUser VARCHAR (255) 
	DECLARE @PropertyValue DATETIME
	DECLARE @DefaultEmailAddress VARCHAR (50)

	DECLARE @Subject	VARCHAR(255)
	DECLARE @Body		VARCHAR(300)

	OPEN curSendGPRSAlerts
	FETCH NEXT FROM curSendGPRSAlerts INTO @CustomerName, @SiteID, @EDISID, @PubName, @SiteUser, @PropertyValue, @DefaultEmailAddress

	WHILE @@FETCH_STATUS = 0

	BEGIN
		Set @Subject = 'GPRS Connection Alert For Site: ' +  @SiteID + ' (' + @CustomerName + ')' 
		Set @Body = '<HTML><body> <FONT FACE="Calibri" SIZE="3"  color="black"><p>Customer Name: ' + @CustomerName + '</p>' +
								 '<p>Site ID: ' + @SiteID + '</p>' +
								 '<p>Site Name: ' + @PubName + '</p>' +
								 '<p>Last GPRS Connection: ' + CAST(@PropertyValue AS VARCHAR) + '</p>' +
								 '<p>There has been no GPRS Connection to this site for the last 24 hours.</p></body></HTML>'
								 
		EXEC SendEmail 'GPRSAlerts@brulines.co.uk', 'GPRS Connection Alerts', @DefaultEmailAddress, @Subject, @Body
		
		FETCH NEXT FROM curSendGPRSAlerts INTO @CustomerName, @SiteID, @EDISID, @PubName, @SiteUser, @PropertyValue, @DefaultEmailAddress
	END

	CLOSE curSendGPRSAlerts
	DEALLOCATE curSendGPRSAlerts

END