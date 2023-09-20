CREATE PROCEDURE [dbo].[GetCallSLAChargingReportByContractAge]
(
	@From		DATETIME,
	@To			DATETIME
)
AS

SET NOCOUNT ON

CREATE TABLE #CallFaultTypes([ID] INT NOT NULL, 
							[Description] VARCHAR(255) NOT NULL, 
							RequiresAdditionalInfo BIT NOT NULL, 
							MaxOccurences INT NOT NULL, 
							PreventsDownload BIT NOT NULL, 
							ForceRequirePO BIT NOT NULL, 
							ForceNotRequirePO BIT NOT NULL, 
							DefaultEngineer INT NULL, 
							AdditionalInfoType INT NOT NULL, 
							DisplayColour INT NOT NULL, 
							WorkDetailDescription VARCHAR(8000) NULL, 
							Depreciated BIT NOT NULL, 
							CallType INT NOT NULL, 
							SLA INT NOT NULL,
							Category VARCHAR(50) NULL,
							ExcludeFromReporting BIT NOT NULL)
							
CREATE TABLE #DefaultItemPrices ([ID] INT,
								 ItemPriority INT,
								 [Description] VARCHAR(50),
								 DefaultPrice MONEY,
								 Depreciated BIT,
								 [Type] VARCHAR(20))

DECLARE @CallSLAs TABLE(CallID INT, InSLA BIT, ExcludeFromSLA BIT)
DECLARE @ChargeableCalls TABLE(CallID INT, IsChargeable BIT)
DECLARE @CallCharges TABLE(CallID INT, TotalCharges FLOAT, EquipmentCharges FLOAT, LabourCharges FLOAT)
DECLARE @SiteInfo TABLE(EDISID INT PRIMARY KEY, AllInclusive BIT, ContractID INT, Hidden BIT, [Description] VARCHAR(50))

DECLARE @CompanyName VARCHAR(100)
DECLARE @LiveSites FLOAT
DECLARE @WeekCount FLOAT

SET @WeekCount = CASE WHEN DATEDIFF(WEEK, @From, @To) = 0 THEN 1 ELSE DATEDIFF(WEEK, @From, @To) END

SELECT @CompanyName = CAST(PropertyValue AS VARCHAR)
FROM Configuration
WHERE PropertyName = 'Company Name'

SELECT @LiveSites = COUNT(*)
FROM Sites
WHERE Hidden = 0

INSERT INTO #CallFaultTypes
EXEC [EDISSQL1\SQL1].ServiceLogger.dbo.GetCallFaultTypes

INSERT INTO #DefaultItemPrices
EXEC dbo.GetDefaultItemPrices

INSERT INTO @ChargeableCalls
SELECT [ID], IsChargeable
FROM Calls
WHERE ClosedOn BETWEEN @From AND DATEADD(SECOND, -1, DATEADD(DAY, 1, @To))


INSERT INTO @SiteInfo (EDISID, AllInclusive, ContractID, Hidden, [Description])
SELECT Sites.EDISID, AllInclusive, ContractID, Hidden, [Description]
FROM Sites
JOIN SiteContracts ON SiteContracts.EDISID = Sites.EDISID
JOIN Contracts ON Contracts.ID = SiteContracts.ContractID

INSERT INTO @CallSLAs
SELECT CallSLAs.[ID], CASE WHEN (CASE WHEN ClosedOn IS NULL THEN dbo.fnGetWeekdayCount(COALESCE(CASE WHEN YEAR(POConfirmed) > 1950 THEN POConfirmed ELSE NULL END, RaisedOn), GETDATE()) ELSE dbo.fnGetWeekdayCount(COALESCE(CASE WHEN YEAR(POConfirmed) > 1950 THEN POConfirmed ELSE NULL END, RaisedOn), ClosedOn) END) > SLA THEN 0 ELSE 1 END AS InSLA, 0
FROM
(
SELECT	Calls.[ID],
		Calls.RaisedOn,
		Calls.ClosedOn,
		Calls.DaysOnHold,
		Calls.POConfirmed,
		MAX(CASE WHEN OverrideSLA > 0 THEN OverrideSLA
			 WHEN CallTypeID = 2 AND SalesReference LIKE 'TRA%'	THEN 21
		     WHEN CallTypeID = 2 AND SalesReference NOT LIKE 'TRA%'THEN 7
		     ELSE COALESCE(CallFaults.SLA, CallFaultTypes.SLA, 0) END) AS SLA
FROM Calls
LEFT JOIN CallFaults ON CallFaults.CallID = Calls.[ID]
LEFT JOIN #CallFaultTypes AS CallFaultTypes ON CallFaultTypes.[ID] = CallFaults.FaultTypeID
WHERE ClosedOn BETWEEN @From AND DATEADD(SECOND, -1, DATEADD(DAY, 1, @To))
GROUP BY Calls.[ID], Calls.RaisedOn, Calls.ClosedOn, Calls.DaysOnHold, Calls.POConfirmed
) AS CallSLAs
GROUP BY CallSLAs.[ID], CallSLAs.RaisedOn, CallSLAs.ClosedOn, CallSLAs.POConfirmed, CallSLAs.SLA

DELETE
FROM @CallSLAs
WHERE CallID IN
(
	SELECT Calls.CallID 
	FROM @CallSLAs AS Calls
	JOIN CallFaults ON CallFaults.CallID = Calls.CallID
	JOIN #CallFaultTypes AS CallFaultTypes ON CallFaultTypes.[ID] = CallFaults.FaultTypeID
	WHERE ExcludeFromReporting = 1
)

INSERT INTO @CallCharges
SELECT Calls.[ID],
	   SUM(CASE WHEN Calls.IsChargeable = 1 THEN InvoiceItems.Cost ELSE 0 END) AS TotalCharges,
	   SUM(CASE WHEN DefaultItemPrices.[Type] = 'Equipment' AND Calls.IsChargeable = 1 THEN InvoiceItems.Cost ELSE 0 END) AS EquipmentCharges,
	   SUM(CASE WHEN DefaultItemPrices.[Type] = 'Labour' AND Calls.IsChargeable = 1 THEN InvoiceItems.Cost ELSE 0 END) AS LabourCharges
FROM Calls
JOIN @CallSLAs AS CallSLAs ON CallSLAs.CallID = Calls.[ID]
LEFT JOIN InvoiceItems ON InvoiceItems.CallID = Calls.[ID]
LEFT JOIN #DefaultItemPrices AS DefaultItemPrices ON DefaultItemPrices.[ID] = InvoiceItems.ItemID
GROUP BY Calls.[ID]

--SELECT * FROM @CallCharges

SELECT @CompanyName AS Company,
	   @LiveSites AS TotalCustomerSites,
	   ContractInfo.SitesInContract,
	   SiteInfo.AllInclusive,
	   0 AS OldAge,
	   CASE WHEN SiteInfo.[Description] IS NULL THEN 'No Contract' ELSE [Description] END AS ContractDescription,	   COUNT(Calls.[ID]) AS TotalCalls,
	   SUM(CASE WHEN InvoicedOn IS NOT NULL THEN 1 ELSE 0 END) AS TotalInvoicedCalls,
	   SUM(CASE WHEN Calls.AbortReasonID = 0 AND InvoicedOn IS NOT NULL THEN 1 ELSE 0 END) AS TotalCallsExcludingAborted,
	   CASE WHEN ContractInfo.SitesInContract = 0 THEN 0 ELSE (SUM(CASE WHEN Calls.AbortReasonID = 0 AND InvoicedOn IS NOT NULL THEN 1 ELSE 0 END) / ContractInfo.SitesInContract) / @WeekCount * 52 END AS CallsPerSiteAnnual,
	   SUM(CASE WHEN Calls.AbortReasonID IN (1, 2, 4, 5) AND InvoicedOn IS NOT NULL THEN 1 ELSE 0 END) AS TotalAborts,
	   CASE WHEN SUM(CASE WHEN InvoicedOn IS NOT NULL THEN 1 ELSE 0 END) = 0 THEN 0 ELSE SUM(CASE WHEN Calls.AbortReasonID IN (1, 2, 4, 5) AND InvoicedOn IS NOT NULL THEN 1 ELSE 0 END) / CAST(SUM(CASE WHEN InvoicedOn IS NOT NULL THEN 1 ELSE 0 END) AS FLOAT) END AS OverallCallsAborted,
	   CASE WHEN SUM(CASE WHEN Calls.AbortReasonID IN (1, 2, 4, 5) AND InvoicedOn IS NOT NULL THEN 1 ELSE 0 END) = 0 THEN 0 ELSE SUM(CASE WHEN Calls.AbortReasonID IN (1, 2, 4, 5) AND ChargeableCalls.IsChargeable = 1 AND InvoicedOn IS NOT NULL THEN 1 ELSE 0 END) / CAST(SUM(CASE WHEN Calls.AbortReasonID IN (1, 2, 4, 5) AND InvoicedOn IS NOT NULL THEN 1 ELSE 0 END) AS FLOAT) END AS AbortedCallsChargeable,
	   SUM(CASE WHEN Calls.AbortReasonID = 0 AND ChargeableCalls.IsChargeable = 1 AND InvoicedOn IS NOT NULL THEN 1 ELSE 0 END) AS ChargeableNonAborted,
	   CASE WHEN SUM(CASE WHEN Calls.AbortReasonID = 0 AND InvoicedOn IS NOT NULL THEN 1 ELSE 0 END) = 0 THEN 0 ELSE SUM(CASE WHEN Calls.AbortReasonID = 0 AND ChargeableCalls.IsChargeable = 1 AND InvoicedOn IS NOT NULL THEN 1 ELSE 0 END) / CAST(SUM(CASE WHEN Calls.AbortReasonID = 0 AND InvoicedOn IS NOT NULL THEN 1 ELSE 0 END) AS FLOAT) END AS ChargeableFromTotal,
	   CASE WHEN ContractInfo.SitesInContract = 0 THEN 0 ELSE (((SUM(CASE WHEN Calls.AbortReasonID = 0 AND InvoicedOn IS NOT NULL THEN 1 ELSE 0 END) - SUM(CASE WHEN Calls.AbortReasonID = 0 AND ChargeableCalls.IsChargeable = 1 AND InvoicedOn IS NOT NULL THEN 1 ELSE 0 END)) / ContractInfo.SitesInContract) / @WeekCount) * 52 END AS ContractedCallsAnnual,
	   SUM(CASE WHEN InvoicedOn IS NOT NULL THEN CallCharges.TotalCharges ELSE 0 END) AS TotalCharges,
	   SUM(CASE WHEN InvoicedOn IS NOT NULL THEN CallCharges.EquipmentCharges ELSE 0 END) AS EquipmentCharges,
	   SUM(CASE WHEN InvoicedOn IS NOT NULL THEN CallCharges.LabourCharges ELSE 0 END) AS LabourCharges,
	   CASE WHEN SUM(CASE WHEN Calls.AbortReasonID = 0 AND ChargeableCalls.IsChargeable = 1 AND InvoicedOn IS NOT NULL THEN 1 ELSE 0 END) = 0 THEN 0 ELSE SUM(CASE WHEN ChargeableCalls.IsChargeable = 1 AND InvoicedOn IS NOT NULL THEN TotalCharges ELSE 0 END) / SUM(CASE WHEN Calls.AbortReasonID = 0 AND ChargeableCalls.IsChargeable = 1 AND InvoicedOn IS NOT NULL THEN 1 ELSE 0 END) END AS AvgChargePerChargeableCall,
	   SUM(CASE WHEN Calls.NumberOfVisits = 1 THEN 1 ELSE 0 END) AS CallsFirstTime,
	   CASE WHEN COUNT(Calls.[ID]) = 0 THEN 0 ELSE SUM(CASE WHEN Calls.NumberOfVisits = 1 THEN 1 ELSE 0 END) / CAST(COUNT(Calls.[ID]) AS FLOAT) END PercentFirstTime,
	   SUM(CASE WHEN Calls.PlanningIssueID = 1 THEN 1 ELSE 0 END) AS CallsNoIssue,
	   CASE WHEN SUM(CASE WHEN Calls.PlanningIssueID = 1 THEN 1 ELSE 0 END) = 0 THEN 0 ELSE SUM(CASE WHEN CallSLAs.InSLA = 1 THEN 1 ELSE 0 END) / CAST(SUM(CASE WHEN Calls.PlanningIssueID = 1 THEN 1 ELSE 0 END) AS FLOAT) END AS InSLA,
	   SUM(CASE WHEN CallSLAs.InSLA = 1 THEN 1 ELSE 0 END) AS CallsInSLACount,
	   SUM(CASE WHEN Calls.PriorityID = 2 THEN 1 ELSE 0 END) AS PriorityCalls,
	   CASE WHEN SUM(CASE WHEN Calls.PriorityID = 2 THEN 1 ELSE 0 END) = 0 THEN 0 ELSE SUM(CASE WHEN CallSLAs.InSLA = 1 AND Calls.PriorityID = 2 THEN 1 ELSE 0 END) / CAST(SUM(CASE WHEN Calls.PriorityID = 2 THEN 1 ELSE 0 END) AS FLOAT) END AS PriorityCallsInSLA,
	   SUM(CASE WHEN CallSLAs.InSLA = 1 AND Calls.PriorityID = 2 THEN 1 ELSE 0 END) AS PriorityCallsInSLACount,
	   SUM(CASE WHEN Calls.PlanningIssueID > 1 THEN 1 ELSE 0 END) AS CallsWithIssues,
	   SUM(CASE WHEN Calls.PlanningIssueID = 2 THEN 1 ELSE 0 END) AS IncorrectSiteDetails,
	   SUM(CASE WHEN Calls.PlanningIssueID = 3 THEN 1 ELSE 0 END) AS UnableToContactLessee,
	   SUM(CASE WHEN Calls.PlanningIssueID = 4 THEN 1 ELSE 0 END) AS AppointmentNotSuitable,
	   SUM(CASE WHEN Calls.PlanningIssueID = 5 THEN 1 ELSE 0 END) AS TenantRefusedAccess,
	   SUM(CASE WHEN Calls.PlanningIssueID = 6 THEN 1 ELSE 0 END) AS UndergoingRefurb,
	   SUM(CASE WHEN Calls.PlanningIssueID = 7 THEN 1 ELSE 0 END) AS BRMRequest,
	   SUM(CASE WHEN Calls.PlanningIssueID = 8 THEN 1 ELSE 0 END) AS ElectricalWorkRequired,
	   SUM(CASE WHEN Calls.PlanningIssueID = 9 THEN 1 ELSE 0 END) AS BTIssue,
	   SUM(CASE WHEN Calls.PlanningIssueID = 10 THEN 1 ELSE 0 END) AS MultipleFailureReasons,
	   @WeekCount AS WeekCount,
	   SUM(CASE WHEN Calls.AbortReasonID = 0 THEN 1 ELSE 0 END) AS CompletedCalls
FROM Calls
JOIN @CallSLAs AS CallSLAs ON CallSLAs.CallID = Calls.[ID]
JOIN @ChargeableCalls AS ChargeableCalls ON ChargeableCalls.CallID = Calls.[ID]
JOIN @CallCharges AS CallCharges ON CallCharges.CallID = Calls.[ID]
JOIN @SiteInfo AS SiteInfo ON SiteInfo.EDISID = Calls.EDISID
JOIN (
	SELECT ContractID, CAST(COUNT(*) AS FLOAT) AS SitesInContract
	FROM @SiteInfo
	WHERE Hidden = 0
	GROUP BY ContractID
) AS ContractInfo ON (ContractInfo.ContractID = SiteInfo.ContractID)
WHERE Calls.AbortReasonID <> 3
AND Calls.CallCategoryID NOT IN (2, 3, 4, 7)
GROUP BY		ContractInfo.SitesInContract,
			   SiteInfo.AllInclusive,
			    CASE WHEN SiteInfo.[Description] IS NULL THEN 'No Contract' ELSE [Description] END

DROP TABLE #DefaultItemPrices
DROP TABLE #CallFaultTypes

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetCallSLAChargingReportByContractAge] TO PUBLIC
    AS [dbo];

