
CREATE PROCEDURE [dbo].[RefreshHandheldCall]
(
	@CallID				INT,
	@RefreshCallInfo	BIT = 1,
	@RefreshComments	BIT = 1,
	@RefreshSiteInfo	BIT = 1,
	@MethodName			VARCHAR(500) = 'Unknown'
)
AS

SET NOCOUNT ON

CREATE TABLE #ContractorEngineers ([ID] INT,
									[Name] VARCHAR(100),
									Mobile VARCHAR(50),
									Active BIT,
									LoginID INT,
									[Login] VARCHAR(100),
									ExtensionNumber VARCHAR(15),
									Address1 VARCHAR(512),
									Address2 VARCHAR(512),
									Address3 VARCHAR(512),
									Address4 VARCHAR(512),
									PostCode VARCHAR(15),
									HouseLongitude FLOAT,
									HouseLatitude FLOAT, 
									HandheldIMEI VARCHAR(15))
									
									
CREATE TABLE #Logins ([ID] INT,
						[Login] VARCHAR(100),
						UserLevel INT,
						IsDevelopment BIT,
						LastUsed DATETIME,
						ExtensionNumber VARCHAR(15),
						IsTeamLeader BIT,
						TeamLeader INT,
						UserGrade VARCHAR(20),
						CanAuditPAYG BIT,
						DirectDialNumber VARCHAR(25),
						IsCoordinator BIT,
						ShowAllSites BIT,
						NiceLogin VARCHAR(255),
						CanBypassPrerelease BIT)

DECLARE @Server		VARCHAR(100)
DECLARE @Name		VARCHAR(100)
DECLARE @SQL		NVARCHAR(1024)
DECLARE @ID			INT
DECLARE @CompanyName	VARCHAR(100)
DECLARE @DatabaseID	INT
DECLARE @EDISID		INT
DECLARE @DBServer	VARCHAR(100)
DECLARE @DBName		VARCHAR(100)

--BEGIN TRAN

SELECT @DatabaseID = CAST(PropertyValue AS INTEGER)
FROM Configuration
WHERE PropertyName = 'Service Owner ID'
									
SELECT @DBName = [Name], @DBServer = [Server]
FROM [SQL1\SQL1].[ServiceLogger].dbo.EDISDatabases
WHERE [ID] = @DatabaseID

INSERT INTO #ContractorEngineers ([ID],
									[Name],
									Mobile,
									Active,
									LoginID,
									[Login],
									ExtensionNumber,
									Address1,
									Address2,
									Address3,
									Address4,
									PostCode,
									HouseLongitude,
									HouseLatitude,
									HandheldIMEI)
							
EXEC [SQL1\SQL1].[ServiceLogger].dbo.GetContractorEngineers 1

INSERT INTO #Logins ([ID],
						[Login],
						UserLevel,
						IsDevelopment,
						LastUsed,
						ExtensionNumber,
						IsTeamLeader,
						TeamLeader,
						UserGrade,
						CanAuditPAYG,
						DirectDialNumber,
						IsCoordinator,
						ShowAllSites,
						NiceLogin,
						CanBypassPrerelease)
EXEC [SQL1\SQL1].[ServiceLogger].dbo.GetLogins

CREATE TABLE #CallSiteInformation (
	   DatabaseID INT,
	   CallID INT,
	   Customer VARCHAR(100),
	   EDISID INT,
	   CallReference VARCHAR(50),
	   JobType VARCHAR(20),
	   Faults VARCHAR(8000),
	   Notes VARCHAR(1000),
	   EngineerID INT,
	   SiteID VARCHAR(50),
	   Name VARCHAR(60),
	   FullAddress VARCHAR(500),
	   PostCode VARCHAR(15),
	   SiteTelNo VARCHAR(100),
	   EDISTelNo VARCHAR(50),
	   TenantName VARCHAR(50),
	   SystemType VARCHAR(50),
	   Auditor VARCHAR(100),
	   GlasswareStatus VARCHAR(20),
	   NetworkOperator VARCHAR(255),
	   UseBillingItems BIT
	)

INSERT INTO #CallSiteInformation (DatabaseID,
	   CallID,
	   Customer,
	   EDISID,
	   CallReference,
	   JobType,
	   Faults,
	   Notes,
	   EngineerID,
	   SiteID,
	   Name,
	   FullAddress,
	   PostCode,
	   SiteTelNo,
	   EDISTelNo,
	   TenantName,
	   SystemType,
	   Auditor,
	   GlasswareStatus,
	   NetworkOperator,
	   UseBillingItems)
EXEC dbo.GetHandheldCallDetails @CallID

CREATE TABLE #UpcomingEngineerJobs (DatabaseID INT,
								CallID INT, 
								[Server] VARCHAR(50),
								[Name] VARCHAR(60),
								EngineerID INT,
								JobDate DATETIME,
								StartTime DATETIME,
								EndTime DATETIME)

INSERT INTO #UpcomingEngineerJobs
SELECT EngineerJobs.DatabaseID,
	   EngineerJobs.CallID,
	   @DBServer,
	   @DBName,
	   EngineerID,
	   JobDate,
	   StartTime,
	   DATEADD(MINUTE, Duration, StartTime) AS EndTime
FROM [EDISSQL1\SQL1].[ServiceLogger].dbo.EngineerJobs AS EngineerJobs
JOIN (SELECT DatabaseID,
			 CallID,
			 MAX([ID]) AS [ID]
	  FROM [EDISSQL1\SQL1].[ServiceLogger].dbo.EngineerJobs
	  GROUP BY DatabaseID, CallID) AS LatestCallJob ON LatestCallJob.DatabaseID = EngineerJobs.DatabaseID
						AND LatestCallJob.CallID = EngineerJobs.CallID
						AND LatestCallJob.[ID] = EngineerJobs.[ID]
WHERE JobDate >= DATEADD(dd, 0, DATEDIFF(dd, 0, GETDATE()))
AND (@DatabaseID = EngineerJobs.DatabaseID OR @DatabaseID IS NULL)
AND (@CallID = EngineerJobs.CallID OR @CallID IS NULL)

--INSERT INTO #UpcomingEngineerJobs
--SELECT DatabaseID,
--	   CallID,
--	   @DBServer,
--	   @DBName,
--	   EngineerID,
--	   JobDate,
--	   StartTime,
--	   DATEADD(MINUTE, Duration, StartTime) AS EndTime
--FROM [EDISSQL1\SQL1].[ServiceLogger].dbo.EngineerJobs
--WHERE JobDate >= DATEADD(dd, 0, DATEDIFF(dd, 0, GETDATE()))
--AND (@DatabaseID = DatabaseID)
--AND (@CallID = CallID)
----ORDER BY [ID] DESC
	
IF @RefreshCallInfo = 1
BEGIN
	CREATE TABLE #UnscheduledEngineerJobs (DatabaseID INT,
									   CallID INT,
									   EngineerID INT)

	INSERT INTO #UnscheduledEngineerJobs (DatabaseID,
									   CallID,
									   EngineerID)
	EXEC dbo.GetHandheldUnscheduledCalls
								
	INSERT INTO #UpcomingEngineerJobs
	SELECT DatabaseID,
		   CallID,
		   @DBServer,
		   @DBName,
		   EngineerID,
		   NULL,
		   NULL,
		   NULL
	FROM #UnscheduledEngineerJobs
	WHERE DatabaseID = @DatabaseID
	AND CallID = @CallID
	
	--BEGIN TRAN

	EXEC [EDISSQL1\SQL1].Handheld.dbo.DeleteHandheldCall @DatabaseID, @CallID

	INSERT INTO [EDISSQL1\SQL1].[Handheld].dbo.Calls 
		  (DatabaseID, CallID, EDISID, CallReference, JobType, EngineerID, VisitDate, VisitTimeStart, VisitTimeEnd, Faults, Coordinator, CoordinatorPhoneNumber, UseBillingItems)
	SELECT UpcomingEngineerJobs.DatabaseID,
		   UpcomingEngineerJobs.CallID,
		   EDISID,
		   CallReference,
		   JobType,
		   UpcomingEngineerJobs.EngineerID,
		   JobDate,
		   StartTime,
		   EndTime,
		   Faults,
		   dbo.udfNiceName(Logins.[Login]) AS CoordinatorName,
		   Logins.DirectDialNumber AS CoordinatorPhoneNumber,
		   ISNULL(UseBillingItems,0)
	FROM #CallSiteInformation
	JOIN #UpcomingEngineerJobs AS UpcomingEngineerJobs ON UpcomingEngineerJobs.DatabaseID = #CallSiteInformation.DatabaseID
	AND UpcomingEngineerJobs.CallID = #CallSiteInformation.CallID
	LEFT JOIN #ContractorEngineers AS ContractorEngineers ON ContractorEngineers.[ID] = UpcomingEngineerJobs.EngineerID
	LEFT JOIN #Logins AS Logins ON Logins.[ID] = ContractorEngineers.LoginID
	GROUP BY UpcomingEngineerJobs.DatabaseID,
		   UpcomingEngineerJobs.CallID,
		   EDISID,
		   CallReference,
		   JobType,
		   UpcomingEngineerJobs.EngineerID,
		   JobDate,
		   StartTime,
		   EndTime,
		   Faults,
		   dbo.udfNiceName(Logins.[Login]),
		   Logins.DirectDialNumber,
		   UseBillingItems
	
	DROP TABLE #UnscheduledEngineerJobs
	
END

IF @RefreshComments = 1
BEGIN
	CREATE TABLE #CallComments (
	   DatabaseID INT,
	   CallCommentID INT,
	   CallID INT,
	   [Date] DATETIME,
	   Comment TEXT,
	   CommentBy VARCHAR(255)
	)

	INSERT INTO #CallComments (DatabaseID,
							   CallCommentID,
							   CallID,
							   [Date],
							   Comment,
							   CommentBy)
	EXEC dbo.GetHandheldCallComments @CallID

	EXEC [EDISSQL1\SQL1].[Handheld].dbo.DeleteHandheldCallComments @DatabaseID, @CallID

	INSERT INTO [EDISSQL1\SQL1].[Handheld].dbo.CallComments (DatabaseID, CallCommentID, CallID, [Date], [Comment], CommentBy)
	SELECT DatabaseID,
		   CallCommentID,
		   CallID,
		   [Date],
		   CAST(Comment AS VARCHAR(8000)) AS Comment,
		   CommentBy
	FROM #CallComments
	GROUP BY DatabaseID,
			CallCommentID,
			CallID,
			[Date],
			CAST(Comment AS VARCHAR(8000)),
			CommentBy
			
	DROP TABLE #CallComments
	
END

IF @RefreshSiteInfo = 1
BEGIN
	CREATE TABLE #SiteCallHistory (
		DatabaseID INT,
		EDISID INT,
		CallID INT,
		EngineerID INT,
		[Name] VARCHAR(100),
		Faults VARCHAR(8000),
		WorkDone VARCHAR(1000),
		WorkDetailComment VARCHAR(8000),
		TamperingID INT,
		VisitDate DATETIME,
		CalChecksCompletedID INT
	
	)
	
	CREATE TABLE #VRSTampering (
		[ID] INT,
		[Description] VARCHAR(100)	
	)
	
	CREATE TABLE #VRSCalChecksCompleted (
		[ID] INT,
		[Description] VARCHAR(100)
	)
	
	SELECT @EDISID = EDISID
	FROM [EDISSQL1\SQL1].[Handheld].dbo.Calls
	WHERE DatabaseID = @DatabaseID
	AND CallID = @CallID

	EXEC [EDISSQL1\SQL1].[Handheld].dbo.DeleteSite @DatabaseID, @EDISID

	INSERT INTO [EDISSQL1\SQL1].[Handheld].dbo.Sites
				([DatabaseID]
				  ,[EDISID]
				  ,[Customer]
				  ,[SiteID]
				  ,[Name]
				  ,[FullAddress]
				  ,[Postcode]
				  ,[SiteTelNo]
				  ,[EDISTelNo]
				  ,[Tenant]
				  ,[SystemType]
				  ,[GlasswareStatus]
				  ,[CalibrationDue]
				  ,[Auditor]
				  ,[AuditorPhoneNumber]
				  ,[Notes]
				  ,[NetworkOperator])
	SELECT #CallSiteInformation.DatabaseID,
		   EDISID,
		   Customer,
		   SiteID,
		   #CallSiteInformation.Name,
		   FullAddress,
		   PostCode,
		   SiteTelNo,
		   EDISTelNo,
		   TenantName,
		   SystemType,
		   GlasswareStatus,
		   NULL,
		   dbo.udfNiceName(AuditorLogin.[Login]) AS AuditorName,
		   AuditorLogin.ExtensionNumber AS AuditorPhoneNumber,
		   Notes,
		   NetworkOperator
	FROM #CallSiteInformation
	JOIN #UpcomingEngineerJobs AS UpcomingEngineerJobs ON UpcomingEngineerJobs.DatabaseID = #CallSiteInformation.DatabaseID									  														AND UpcomingEngineerJobs.CallID = #CallSiteInformation.CallID
	LEFT JOIN #Logins AS AuditorLogin ON dbo.udfNiceName(AuditorLogin.[Login]) = #CallSiteInformation.Auditor
	GROUP BY #CallSiteInformation.DatabaseID,
		   EDISID,
		   Customer,
		   SiteID,
		   #CallSiteInformation.Name,
		   FullAddress,
		   PostCode,
		   SiteTelNo,
		   EDISTelNo,
		   TenantName,
		   SystemType,
		   GlasswareStatus,
		   dbo.udfNiceName(AuditorLogin.[Login]),
		   AuditorLogin.ExtensionNumber,
		   Notes,
		   NetworkOperator
		   
	INSERT INTO #SiteCallHistory (DatabaseID,
								EDISID,
								CallID,
								EngineerID,
								[Name],
								Faults,
								WorkDone,
								WorkDetailComment,
								TamperingID,
								VisitDate,
								CalChecksCompletedID)
	EXEC GetHandheldCallHistory @CallID
		   
	INSERT INTO #VRSTampering ([ID], [Description])
	EXEC [EDISSQL1\SQL1].ServiceLogger.dbo.GetVRSTampering
	
	INSERT INTO #VRSCalChecksCompleted ([ID], [Description])
	EXEC [EDISSQL1\SQL1].ServiceLogger.dbo.GetVRSCalChecksCompleted

	EXEC [EDISSQL1\SQL1].[Handheld].dbo.DeleteSiteCallHistory @DatabaseID, @EDISID

	INSERT INTO [EDISSQL1\SQL1].[Handheld].dbo.SiteCallHistory
				([DatabaseID]
				  ,[EDISID]
				  ,[Date]
				  ,[Engineer]
				  ,[Faults]
				  ,[WorkDone]
				  ,[WorkDetailComment]
				  ,[Tampering])
	SELECT SiteCallHistory.DatabaseID,
		   EDISID,
		   SiteCallHistory.VisitDate AS [Date],
		   COALESCE(SiteCallHistory.[Name], ContractorEngineers.[Name]) AS [Name],
		   Faults,
		   COALESCE(VRSCalChecksCompleted.[Description], WorkDone) AS WorkDone,
		   WorkDetailComment,
		   VRSTampering.[Description]
	FROM #SiteCallHistory AS SiteCallHistory
	LEFT JOIN #ContractorEngineers AS ContractorEngineers ON ContractorEngineers.[ID] = SiteCallHistory.EngineerID
	LEFT JOIN #VRSTampering AS VRSTampering ON VRSTampering.[ID] = SiteCallHistory.TamperingID
	LEFT JOIN #VRSCalChecksCompleted AS VRSCalChecksCompleted ON VRSCalChecksCompleted.[ID] = SiteCallHistory.CalChecksCompletedID

	DROP TABLE #SiteCallHistory
	DROP TABLE #VRSTampering
	DROP TABLE #VRSCalChecksCompleted
	
END

DROP TABLE #UpcomingEngineerJobs
DROP TABLE #ContractorEngineers
DROP TABLE #Logins
DROP TABLE #CallSiteInformation

EXEC dbo.RefreshActiveLoggerCalls @CallID


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[RefreshHandheldCall] TO PUBLIC
    AS [dbo];

