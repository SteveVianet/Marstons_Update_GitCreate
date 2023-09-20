CREATE PROCEDURE [dbo].[RefreshActiveLoggerCalls]
(
	@CallID		INT = NULL
)
AS

SET NOCOUNT ON

DECLARE @DatabaseID INT
DECLARE @CallCount INT

SELECT @DatabaseID = CAST(Configuration.PropertyValue AS INTEGER)
FROM dbo.Configuration
WHERE PropertyName = 'Service Owner ID'

INSERT INTO dbo.ActiveLoggerCallsLog
(ID, [Time], RefreshUser, CallID, RefreshedFrom)
VALUES
(1, GETDATE(), SUSER_NAME(), @CallID, NULL)

SELECT @CallCount = COUNT(*)
FROM [EDISSQL1\SQL1].[Handheld].[dbo].[ActiveLoggerCalls]
WHERE DatabaseID = @DatabaseID
AND (CallID = @CallID OR @CallID IS NULL)

IF @CallCount > 0
BEGIN
	DELETE
	FROM [EDISSQL1\SQL1].[Handheld].[dbo].[ActiveLoggerCalls]
	WHERE DatabaseID = @DatabaseID
	AND (CallID = @CallID OR @CallID IS NULL)
END

INSERT INTO [EDISSQL1\SQL1].[Handheld].[dbo].[ActiveLoggerCalls]
           ([DatabaseID]
           ,[CallID]
           ,[CompanyName]
           ,[EDISID]
           ,[SiteID]
           ,[CallReference]
           ,[CoordinatorID]
           ,[CoordinatorName]
           ,[EngineerID]
           ,[EngineerName]
           ,[SiteName]
           ,[SiteTown]
           ,[SitePostcode]
           ,[SiteTelNo]
           ,[InSLA]
           ,[CallTypeID]
           ,[BookedOn]
           ,[IsComplete]
           ,[IsPOStatusRequired]
           ,[IsOnHold]
           ,[LicenseeName]
           ,[CallPriorityID]
           ,[CallPriorityName]
           ,[SystemType]
           ,[MonitoringType]
           ,[DaysOnHold]
           ,[LastContactDate]
           ,[LastCallComment]
           ,[CallStatusID]
           ,[CallStatus]
           ,[SLAClock]
           ,[PlanningIssue]
           ,[SalesReference]
           ,[SiteLocationX]
           ,[SiteLocationY]
           ,[RaisedOn]
           ,[Faults]
           ,[QualitySite]
           ,[CallSubStatusID]
           ,[CallSubStatus]
           ,[OwnerName]
           ,[CallTypeColour]
           ,[CallStatusColour]
           ,[CategoryName]
           ,[Locale])
SELECT	@DatabaseID AS DatabaseID,
		Calls.[ID] AS CallID,
		EDISDatabases.CompanyName,
		Calls.EDISID,
		Sites.SiteID,
		dbo.GetCallReference(Calls.[ID]) AS CallReference,
		Coordinators.[ID] AS CoordinatorID,
		dbo.udfNiceName(Coordinators.[Login]) AS CoordinatorName,
		Calls.EngineerID,
		Engineers.Name AS EngineerName,
		Sites.Name AS SiteName,
		COALESCE(Sites.Address3, Sites.Address4) AS SiteTown,
		Sites.PostCode,
		Sites.SiteTelNo,
		Calls.CallWithinSLA AS InSLA,
		Calls.CallTypeID,
		Calls.VisitedOn AS BookedOn,
		CASE WHEN Calls.ClosedOn IS NOT NULL THEN 1 ELSE 0 END AS IsComplete,
		CASE WHEN Calls.POStatusID IN (2, 3) THEN 1 ELSE 0 END AS POStatusRequired,
		CASE WHEN CallStatusHistory.StatusID = 2 THEN 1 ELSE 0 END AS IsOnHold,
		Sites.TenantName,
		Calls.PriorityID,
		CallPriorities.[Description] AS CallPriorityName,
		SystemTypes.[Description] AS SystemType,
		CASE WHEN Calls.QualitySite = 1 THEN 'iDraught' ELSE 'BMS' END AS MonitoringType,
		Calls.DaysOnHold,
		LastCallComment.SubmittedOn AS LastContactDate,
		LastCallComment.Comment,
		CallStatuses.[ID] AS CallStatusID,
		CallStatuses.[Description] AS CallStatus,
		CASE WHEN Calls.POStatusID IN (2, 3) THEN Calls.OverrideSLA ELSE Calls.DaysLeftToCompleteWithinSLA END AS DaysLeftToCompleteWithinSLA,
		CallPlanningIssues.[Description] AS PlanningIssue,
		Calls.SalesReference,
		SiteLocations.LocationX,
		SiteLocations.LocationY,
		Calls.RaisedOn,
		CASE WHEN Calls.UseBillingItems = 1 THEN dbo.udfConcatCallReasons(Calls.[ID]) ELSE dbo.udfConcatCallFaults(Calls.[ID]) END AS CallFaults,
		Calls.QualitySite,
		CallSubStatuses.[ID] AS CallSubStatusID,
		CallSubStatuses.[Description] AS CallSubStatus,
		Owners.Name AS OwnerName,
		CallTypes.DisplayColour AS CallTypeColour,
		CallStatuses.Colour AS CallStatusColour,
		ISNULL(CallCategories.[Description], '') AS CallCategoryName,
		ISNULL(InternationalLocales.Value, 'UK') AS Locale
FROM dbo.CallsSLA AS Calls
JOIN CallStatusHistory ON CallStatusHistory.CallID = Calls.[ID]
JOIN Sites ON Sites.EDISID = Calls.EDISID
JOIN SystemTypes ON SystemTypes.[ID] = Sites.SystemTypeID
LEFT JOIN Owners ON Owners.[ID] = Sites.OwnerID
LEFT JOIN SiteLocations ON SiteLocations.EDISID = Sites.EDISID
JOIN [EDISSQL1\SQL1].ServiceLogger.dbo.EDISDatabases AS EDISDatabases ON EDISDatabases.[ID] = @DatabaseID
JOIN [EDISSQL1\SQL1].ServiceLogger.dbo.CallTypes AS CallTypes ON CallTypes.[ID] = Calls.CallTypeID
JOIN [EDISSQL1\SQL1].ServiceLogger.dbo.CallStatuses AS CallStatuses ON CallStatuses.[ID] = CallStatusHistory.StatusID
LEFT JOIN [EDISSQL1\SQL1].ServiceLogger.dbo.CallCategories AS CallCategories ON CallCategories.[ID] = Calls.CallCategoryID
LEFT JOIN [EDISSQL1\SQL1].ServiceLogger.dbo.CallSubStatuses AS CallSubStatuses ON CallSubStatuses.[ID] = CallStatusHistory.SubStatusID
LEFT JOIN [EDISSQL1\SQL1].ServiceLogger.dbo.ContractorEngineers AS Engineers ON Engineers.[ID] = Calls.EngineerID
LEFT JOIN [EDISSQL1\SQL1].ServiceLogger.dbo.Logins AS Coordinators ON Coordinators.[ID] = Engineers.LoginID
LEFT JOIN [EDISSQL1\SQL1].ServiceLogger.dbo.CallPriorities AS CallPriorities ON CallPriorities.[ID] = Calls.PriorityID
LEFT JOIN [EDISSQL1\SQL1].ServiceLogger.dbo.CallPlanningIssues AS CallPlanningIssues ON CallPlanningIssues.[ID] = Calls.PlanningIssueID
LEFT JOIN
(
	SELECT	CallComments.CallID,
			CallComments.SubmittedOn,
			CallComments.Comment
	FROM CallComments
	WHERE [ID] IN
	(
		SELECT MAX([ID]) AS LastCommentID
		FROM CallComments
		WHERE (CallID = @CallID OR @CallID IS NULL)
		GROUP BY CallID
	)
) AS LastCallComment ON LastCallComment.CallID = Calls.[ID]
LEFT JOIN
(
	SELECT	SiteProperties.EDISID, 
			SiteProperties.Value
	FROM SiteProperties
	JOIN Properties ON Properties.ID = SiteProperties.PropertyID
	WHERE Properties.Name = 'International'
) AS InternationalLocales ON InternationalLocales.EDISID = Sites.EDISID
WHERE CallStatusHistory.[ID] =	(SELECT MAX(CallStatusHistory.[ID])
				FROM dbo.CallStatusHistory
				WHERE CallID = Calls.[ID])
AND (CallStatusHistory.StatusID IN (1, 2, 3))
AND (Calls.[ID] = @CallID OR @CallID IS NULL)
ORDER BY Calls.RaisedOn

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[RefreshActiveLoggerCalls] TO PUBLIC
    AS [dbo];

