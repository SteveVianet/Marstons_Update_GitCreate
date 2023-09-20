CREATE PROCEDURE [dbo].[GenerateCallClosedEmail]
(
	@CallID INT,
	@ReRaisedCall BIT = 0
)
AS

SET NOCOUNT ON

DECLARE @EDISID INT
DECLARE @SiteID VARCHAR(50)
DECLARE @Auditor VARCHAR(100)
DECLARE @CCList VARCHAR(1000)
DECLARE @AccountManager VARCHAR(100)
DECLARE @SiteDescription VARCHAR(250)
DECLARE @SiteDetail VARCHAR(250)
DECLARE @Owner VARCHAR(100)
DECLARE @CallReference VARCHAR(50)
DECLARE @AuthCode VARCHAR(50)
DECLARE @VisitDate DATETIME
DECLARE @CallFaults VARCHAR(8000)
DECLARE @WorkDetail VARCHAR(8000)
DECLARE @BillingItems VARCHAR(8000)
DECLARE @Observations VARCHAR(8000)
DECLARE @Deadtime VARCHAR(8000)
DECLARE @Subject VARCHAR(1000)
DECLARE @Head VARCHAR(1000)
DECLARE @Body VARCHAR(8000)
DECLARE @SLAAchieved VARCHAR(5)
DECLARE @PlanningIssue VARCHAR(100)
DECLARE @ReRaisedCallDescription VARCHAR(5)
DECLARE @VisitStart DATETIME
DECLARE @VisitEnd DATETIME
DECLARE @IncompleteReason VARCHAR(100)
DECLARE @EngineerID INT
DECLARE @EngineerName VARCHAR(100)
DECLARE @EngineerMobile VARCHAR(50)
DECLARE @PlannerName VARCHAR(100)
DECLARE @PlannerID INT
DECLARE @RMName VARCHAR(100)
DECLARE @RMDescription VARCHAR(100)
DECLARE @BDMName VARCHAR(100)
DECLARE @BDMDescription VARCHAR(100)
DECLARE @ServiceIssuesQuality VARCHAR(2000)
DECLARE @ServiceIssuesYield VARCHAR(2000)
DECLARE @ServiceIssuesEquipment VARCHAR(2000)
DECLARE @ServiceIssues VARCHAR(8000)

SELECT	@EDISID = EDISID,
		@CallReference = dbo.GetCallReference(Calls.[ID]),
		@AuthCode = CASE WHEN AuthCode = '' THEN 'N/A' ELSE AuthCode END,
		@VisitDate = VisitedOn,
		@CallFaults = dbo.udfConcatCallReasons(Calls.[ID]),
		@SLAAchieved = CASE WHEN DATEDIFF(DAY, RaisedOn, ClosedOn) <= OverrideSLA THEN 'Yes' ELSE 'No' END,
		@PlanningIssue = CallPlanningIssues.[Description],
		@ReRaisedCallDescription = CASE WHEN @ReRaisedCall = 1 THEN 'Yes' ELSE 'No' END,
		@VisitStart = VisitStartedOn,
		@VisitEnd = VisitEndedOn,
		@IncompleteReason = CASE WHEN IncompleteReasonID > 0 THEN IncompleteReasons.[Description] WHEN AbortReasonID > 0 THEN AbortReasons.[Description] ELSE 'N/A' END,
		@EngineerID = EngineerID
FROM Calls
JOIN [EDISSQL1\SQL1].ServiceLogger.dbo.CallPlanningIssues AS CallPlanningIssues ON CallPlanningIssues.[ID] = Calls.PlanningIssueID
JOIN [EDISSQL1\SQL1].ServiceLogger.dbo.AbortReasons AS AbortReasons ON AbortReasons.[ID] = Calls.AbortReasonID
JOIN [EDISSQL1\SQL1].ServiceLogger.dbo.CallIncompleteReasons AS IncompleteReasons ON IncompleteReasons.[ID] = Calls.IncompleteReasonID
WHERE Calls.[ID]  = @CallID

SELECT @WorkDetail = COALESCE(@WorkDetail + ';', '') + 
LTRIM(
	RTRIM(
		(CONVERT(varchar(11), CallWorkDetailComments.SubmittedOn, 113) + ': ' + 
		CONVERT(varchar(8000), CallWorkDetailComments.WorkDetailComment)
		)
	)
)
FROM CallWorkDetailComments
WHERE CallWorkDetailComments.CallID = @CallID

SELECT @BillingItems = COALESCE(@BillingItems + char(13), '') + (BillingItems.Description + ' (x' + CAST(CallBillingItems.Quantity AS VARCHAR) + ')<br>')
FROM CallBillingItems
JOIN [SQL1\SQL1].ServiceLogger.dbo.BillingItems AS BillingItems ON BillingItems.ID = CallBillingItems.BillingItemID
WHERE CallBillingItems.CallID = @CallID
AND BillingItems.ItemType = 1

SELECT @Observations = COALESCE(@Observations + char(13), '') + (BillingItems.Description + ' (x' + CAST(CallBillingItems.Quantity AS VARCHAR) + ')<br>')
FROM CallBillingItems
JOIN [SQL1\SQL1].ServiceLogger.dbo.BillingItems AS BillingItems ON BillingItems.ID = CallBillingItems.BillingItemID
WHERE CallBillingItems.CallID = @CallID
AND BillingItems.ItemType = 2

SELECT @Deadtime = COALESCE(@Deadtime + char(13), '') + (BillingItems.Description + ' (' + CAST(CallBillingItems.Quantity AS VARCHAR) + ' minutes)<br>')
FROM CallBillingItems
JOIN [SQL1\SQL1].ServiceLogger.dbo.BillingItems AS BillingItems ON BillingItems.ID = CallBillingItems.BillingItemID
WHERE CallBillingItems.CallID = @CallID
AND BillingItems.ItemType = 4

SELECT @ServiceIssuesQuality = COALESCE(@ServiceIssuesQuality + char(13), '') + 'Quality: ' + CAST(RealPumpID AS VARCHAR) + ': ' + Products.[Description] + ' (From: ' + CAST(DateFrom AS VARCHAR) + ' To: ' + CAST(DateTo AS VARCHAR) + ')<br>'
FROM ServiceIssuesQuality
JOIN Products ON Products.ID = ServiceIssuesQuality.ProductID
WHERE CallID = @CallID

SELECT @ServiceIssuesYield = COALESCE(@ServiceIssuesYield + char(13), '') + 'Yield: ' + Products.[Description] + ' (From: ' + CAST(DateFrom AS VARCHAR) + ' To: ' + CAST(DateTo AS VARCHAR) + ')<br>'
FROM ServiceIssuesYield
JOIN Products ON Products.ID = ServiceIssuesYield.ProductID
WHERE CallID = @CallID

SELECT @ServiceIssuesEquipment = COALESCE(@ServiceIssuesEquipment + char(13), '') + 'Equipment: ' + CAST(ServiceIssuesEquipment.InputID AS VARCHAR) + ': ' + EquipmentTypes.[Description] + ' ' + EquipmentItems.[Description] + ' (From: ' + CAST(DateFrom AS VARCHAR) + ' To: ' + CAST(DateTo AS VARCHAR) + ')<br>'
FROM ServiceIssuesEquipment
JOIN EquipmentItems ON EquipmentItems.InputID = ServiceIssuesEquipment.InputID AND EquipmentItems.EDISID = ServiceIssuesEquipment.RealEDISID
JOIN EquipmentTypes ON EquipmentTypes.ID = EquipmentItems.EquipmentTypeID
WHERE CallID = @CallID

SET @ServiceIssues = ISNULL(@ServiceIssuesQuality, '') + ISNULL(@ServiceIssuesYield, '') + ISNULL(@ServiceIssuesEquipment, '')

SELECT	@SiteID = SiteID,
		@SiteDescription = SiteID + ', ' + Sites.Name + ', '  + ISNULL(CASE WHEN Sites.Address4 = '' THEN Sites.Address3 ELSE Sites.Address4 END, ''),
		@SiteDetail = Sites.Name + '; ' + ISNULL(CASE WHEN Sites.Address4 = '' THEN Sites.Address3 ELSE Sites.Address4 END, '') + '; ' + Sites.PostCode,
		@Auditor = SiteUser, 
		@Owner = ISNULL(Owners.Name, '')
FROM Sites
JOIN Owners ON Owners.[ID] = Sites.OwnerID
WHERE EDISID = @EDISID

SELECT @Auditor = dbo.udfNiceName(CASE WHEN @Auditor = '' THEN CAST(PropertyValue AS VARCHAR) ELSE @Auditor END)
FROM Configuration
WHERE PropertyName = 'AuditorName'

SELECT @AccountManager = CAST(PropertyValue AS VARCHAR)
FROM Configuration
WHERE PropertyName = 'AccountManagerName'

IF @EngineerID > 0
BEGIN
	SELECT	@EngineerName = ISNULL(Name, ''),
			@EngineerMobile =  ISNULL(Mobile, ''),
			@PlannerID = ISNULL(LoginID, 0)
	FROM [EDISSQL1\SQL1].ServiceLogger.dbo.ContractorEngineers AS ContractorEngineers
	WHERE [ID] = @EngineerID
	
END
ELSE
BEGIN
	SET @EngineerName = ''
	SET @EngineerMobile = ''
	
END

IF @PlannerID > 0
BEGIN
	SELECT @PlannerName = dbo.udfNiceName([Login])
	FROM [EDISSQL1\SQL1].ServiceLogger.dbo.Logins
	WHERE ID = @PlannerID
	
END
ELSE
BEGIN
	SET @PlannerName = ''
END

SELECT	@BDMName = BDMUser.UserName,
		@RMName = RMUser.UserName
FROM (
	SELECT UserSites.EDISID,
	 	MAX(CASE WHEN UserType = 2 THEN UserID ELSE 0 END) AS BDMID,
		MAX(CASE WHEN UserType = 1 THEN UserID ELSE 0 END) AS RMID
	FROM UserSites
	JOIN Users ON Users.ID = UserSites.UserID
	WHERE UserType IN (1,2) AND UserSites.EDISID = @EDISID
	GROUP BY UserSites.EDISID
) AS SiteManagers
JOIN Users AS BDMUser ON BDMUser.ID = SiteManagers.BDMID
JOIN Users AS RMUser ON RMUser.ID = SiteManagers.RMID

SELECT @RMDescription = [Description]
FROM UserTypes
WHERE ID = 1

SELECT @BDMDescription = [Description]
FROM UserTypes
WHERE ID = 2

SELECT @CCList = CAST(PropertyValue AS VARCHAR)
FROM Configuration
WHERE PropertyName = 'CallClosedCCEmail'

SET @Auditor = REPLACE(@Auditor, ' ', '.') + '@vianetplc.com'
SET @Subject = 'Call Closed - ' + @Owner + ': ' + @SiteDescription

SET @Head = '<html><head>'
			+'<style type="text/css">'
				+ 'html, form, body {padding: 0px; margin: 0px; font-family: Arial; font-size: 1em;} '
			+ '</style>'
			+ '</head><body style="padding: 0px; margin: 0px; font-family: Arial; font-size: 1em;" >'

SET @Body = @Head + '<b><i>Call Ref:</i></b> ' + @CallReference + '<br><br>' +
			'<b><i>PO Auth Code:</i></b> ' + ISNULL(@AuthCode, '') + '<br><br>' +
			'<b><i>Site ID:</i></b> ' + @SiteID + '<br><br>' +
			'<b><i>Site Detail:</i></b><br>' + @SiteDetail + '<br><br>' +
			'<b><i>Visit Date:</i></b> ' + ISNULL(CONVERT(VARCHAR(11), @VisitDate, 113) , '') + '<br><br>' +
			'<b><i>SLA Achieved:</i></b> ' + @SLAAchieved + '<br><br>' +
			'<b><i>Planning Issue:</i></b> ' + @PlanningIssue + '<br><br>' +
			'<b><i>Engineer Name:</i></b> ' + @EngineerName + '<br><br>' +
			'<b><i>Engineer Mobile:</i></b> ' + @EngineerMobile + '<br><br>' +
			'<b><i>Start Time:</i></b> ' + ISNULL(CONVERT(VARCHAR(5), @VisitStart, 114) , '') + '<br><br>' +
			'<b><i>End Time:</i></b> ' + ISNULL(CONVERT(VARCHAR(5), @VisitEnd, 114) , '') + '<br><br>' +
			'<b><i>Time On Site (minutes):</i></b> ' + ISNULL(CAST(DATEDIFF(MINUTE, @VisitStart, @VisitEnd) AS VARCHAR), '') + '<br><br>' +
			'<b><i>Planner:</i></b> ' + ISNULL(@PlannerName, '') + '<br><br>' +
			'<b><i>Fault:</i></b> ' + ISNULL(@CallFaults, '') + '<br><br>' +
			'<b><i>Work Items:</i></b><br>' + ISNULL(@BillingItems, '') + '<br><br>' +
			'<b><i>Observations:</i></b><br>' + ISNULL(@Observations, '') + '<br><br>' +
			'<b><i>Dead Time:</i></b><br>' + ISNULL(@Deadtime, '') + '<br><br>' +
			'<b><i>Comment:</i></b><br><br>' + REPLACE(ISNULL(@WorkDetail, ''), ';', '<br><br>') + '<br><br>' +
			'<b><i>Closed Service Issues:</i></b><br>' + ISNULL(@ServiceIssues, '') + '<br><br>' +
			'<b><i>Re-raised:</i></b> ' + @ReRaisedCallDescription + '<br><br>' +
			'<b><i>Reason:</i></b> ' + @IncompleteReason + '<br><br>' +
			'<b><i>' + ISNULL(@RMDescription, 'RM') + ':</i></b> ' + ISNULL(@RMName, '') + '<br><br>' +
			'<b><i>' + ISNULL(@BDMDescription, 'BDM') + ':</i></b> ' + ISNULL(@BDMName, '') + '<br><br>' +
			'</body></html>'
			
EXEC dbo.SendEmail 'auto@brulines.com', 'Brulines', @Auditor, @Subject, @Body

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GenerateCallClosedEmail] TO PUBLIC
    AS [dbo];

