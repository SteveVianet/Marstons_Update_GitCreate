CREATE PROCEDURE [dbo].[GetAuditorWebServiceCall]

	@CallRefID INTEGER
AS

BEGIN

	SET NOCOUNT ON;

	CREATE TABLE #ServiceCall (CustomerName VARCHAR(50),
						   SiteID VARCHAR(50),
						   SiteName VARCHAR(50),
						   CallPriorityID INT,
						   CallRaisedOn DATE,
						   CallRaisedBy VARCHAR(50),
						   EngineerID INT NULL,   
						   CoOrdinatorName VARCHAR (50) NULL,
						   CoOrdinatorExt VARCHAR (15) NULL,
						   EngineerName VARCHAR(50) NULL,
						   EngineerNumber VARCHAR(255) NULL,
						   CallDueCompleted DATE NULL,
						   CallStatus VARCHAR(255) NULL,
						   CallPriority VARCHAR(255) NULL,
						   CallReference VARCHAR(255))


	CREATE TABLE #EngineerDetails (EngineerID INT,
							   EngineerName VARCHAR(255),
							   EngineerMobile VARCHAR(255),
							   EngineerActive BIT,
							   CoOrdinatorID INT,
							   CoOrdinatorName VARCHAR(255),
							   CoOrdinatorExtension VARCHAR(15),
							   Address1 VARCHAR(255),
							   Address2 VARCHAR(255),
							   Address3 VARCHAR(255),
							   Address4 VARCHAR(255),
							   PostCode VARCHAR(255),
							   HouseLongitude FLOAT,
							   HouseLatitude FLOAT,
							   HandheldIMEI VARCHAR(15))
							   
	--Company Name
	DECLARE @CompanyName VARCHAR(50)
	SELECT @CompanyName = PropertyValue
	From dbo.Configuration
	WHERE PropertyName = 'Company Name'

	INSERT INTO #ServiceCall( CustomerName, SiteID, SiteName, CallPriorityID, CallRaisedOn, CallRaisedBy, EngineerID, CallDueCompleted)
	SELECT	@CompanyName as CustomerName,
		dbo.Sites.SiteID as SiteID,
		dbo.Sites.Name as SiteName,
		dbo.Calls.PriorityID as CallPriorityID,
		dbo.Calls.RaisedOn as RaisedOn,
		dbo.Calls.RaisedBy as RaisedBy,
		dbo.Calls.EngineerID as EngineerID,
		CASE WHEN dbo.Calls.VisitedOn > dbo.Calls.RaisedOn THEN dbo.Calls.VisitedOn ELSE '' END AS DueComplete
	FROM dbo.Calls 
	JOIN dbo.Sites ON dbo.Sites.EDISID = dbo.Calls.EDISID
	WHERE ID = @CallRefID 

	--CallStatusID
	DECLARE @StatusID INT
	SELECT @StatusID = StatusID
	FROM CallStatusHistory
	WHERE ID IN (
	SELECT MAX(ID) AS CallStatus
	FROM CallStatusHistory
	WHERE CallID = @CallRefID
	)

	-- Call Status Description
	DECLARE @CallStatus TABLE(StatusDescription VARCHAR(255))
	INSERT INTO @CallStatus(StatusDescription)
	EXEC [EDISSQL1\SQL1].ServiceLogger.dbo.[GetCallStatus] @StatusID

	--PriorityID
	DECLARE @PriorityID INT
	SELECT @PriorityID = CallPriorityID
	FROM #ServiceCall

	-- Call Prioirty Description
	DECLARE @Priority TABLE(PriorityID INT, PriorityDescription VARCHAR(255), Deprecated BIT)
	INSERT INTO @Priority(PriorityID, PriorityDescription, Deprecated)
	EXEC [EDISSQL1\SQL1].ServiceLogger.[dbo].[GetCallPriorities] @PriorityID

	--EngineerID
	DECLARE @EngineerID INT
	SELECT @EngineerID = EngineerID
	FROM #ServiceCall

	--Engineer Details
	INSERT INTO #EngineerDetails
	(EngineerID, EngineerName, EngineerMobile, EngineerActive, CoOrdinatorID, CoOrdinatorName, CoOrdinatorExtension, Address1, Address2, Address3, Address4, PostCode, HouseLongitude, HouseLatitude, HandheldIMEI)
	EXEC [EDISSQL1\SQL1].ServiceLogger.dbo.[GetContractorEngineers] NULL, @EngineerID
	
	--Add Engineer Details to #ServiceCall
	UPDATE #ServiceCall
	SET CoOrdinatorName = ISNULL(EngineerDetails.CoOrdinatorName, ''),
	CoOrdinatorExt = ISNULL(EngineerDetails.CoOrdinatorExtension, ''),
	EngineerName = ISNULL(EngineerDetails.EngineerName, ''),
	EngineerNumber = ISNULL(EngineerDetails.EngineerMobile, '')
	FROM #EngineerDetails AS EngineerDetails

	--Add Call Status Description to #ServiceCall
	UPDATE #ServiceCall
	SET CallStatus = StatusDescription
	From @CallStatus

	--Add Call Reference 
	DECLARE @CallReference AS VARCHAR(255)
	SELECT @CallReference = dbo.GetCallReference(@CallRefID)
		
	--Add Call Priority Description and Call Reference to #ServiceCall
	UPDATE #ServiceCall
	SET CallPriority = PriorityDescription,
	CallReference = @CallReference
	From @Priority
	
	SELECT CustomerName,
		   SiteID,
		   SiteName,
		   CallPriorityID,
		   CallRaisedOn,
		   CallRaisedBy,
		   EngineerID,
		   CoOrdinatorName,
		   CoOrdinatorExt,
		   EngineerName,
		   EngineerNumber,
		   CallDueCompleted,
		   CallStatus,
		   CallPriority,
		   CallReference
	FROM #ServiceCall
	
	DROP TABLE #ServiceCall
	DROP TABLE #EngineerDetails
END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetAuditorWebServiceCall] TO PUBLIC
    AS [dbo];

