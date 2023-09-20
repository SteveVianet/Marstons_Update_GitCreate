CREATE PROCEDURE [dbo].[GetCallSLAChargingReport]
(
	@From		DATETIME,
	@To			DATETIME
)
AS

SET NOCOUNT ON
							
CREATE TABLE #DefaultItemPrices ([ID] INT,
								 ItemPriority INT,
								 [Description] VARCHAR(50),
								 DefaultPrice MONEY,
								 Depreciated BIT,
								 [Type] VARCHAR(20))

DECLARE @ChargeableCalls TABLE(CallID INT, IsChargeable BIT)
DECLARE @CallCharges TABLE(CallID INT, TotalCharges FLOAT, EquipmentCharges FLOAT, LabourCharges FLOAT)

DECLARE @CompanyName VARCHAR(100)
DECLARE @LiveSites FLOAT
DECLARE @WeekCount FLOAT

SET @WeekCount = CASE WHEN DATEDIFF(WEEK, @From, @To) = 0 THEN 1 ELSE DATEDIFF(WEEK, @From, @To) END

SELECT @CompanyName = CAST(PropertyValue AS VARCHAR)
FROM Configuration
WHERE PropertyName = 'Company Name'

SELECT @LiveSites = COUNT(*)
FROM Sites
WHERE Hidden = 0 --[Status] = 1

INSERT INTO #DefaultItemPrices
EXEC dbo.GetDefaultItemPrices

INSERT INTO @ChargeableCalls
SELECT [ID], IsChargeable
FROM Calls
WHERE ClosedOn BETWEEN @From AND DATEADD(SECOND, -1, DATEADD(DAY, 1, @To))

INSERT INTO @CallCharges
SELECT Calls.[ID],
	   SUM(CASE WHEN Calls.IsChargeable = 1 THEN InvoiceItems.Cost ELSE 0 END) AS TotalCharges,
	   SUM(CASE WHEN DefaultItemPrices.[Type] = 'Equipment' AND Calls.IsChargeable = 1 THEN InvoiceItems.Cost ELSE 0 END) AS EquipmentCharges,
	   SUM(CASE WHEN DefaultItemPrices.[Type] = 'Labour' AND Calls.IsChargeable = 1 THEN InvoiceItems.Cost ELSE 0 END) AS LabourCharges
FROM CallsSLA AS Calls
LEFT JOIN InvoiceItems ON InvoiceItems.CallID = Calls.[ID]
LEFT JOIN #DefaultItemPrices AS DefaultItemPrices ON DefaultItemPrices.[ID] = InvoiceItems.ItemID
GROUP BY Calls.[ID]

SELECT @CompanyName AS Company,
	   @LiveSites AS Sites,
	   COUNT(Calls.[ID]) AS TotalCalls,
	   SUM(CASE WHEN InvoicedOn IS NOT NULL THEN 1 ELSE 0 END) AS TotalInvoicedCalls,
	   SUM(CASE WHEN Calls.AbortReasonID = 0 AND InvoicedOn IS NOT NULL THEN 1 ELSE 0 END) AS TotalCallsExcludingAborted,
	   CASE WHEN @LiveSites = 0 THEN 0 ELSE (SUM(CASE WHEN Calls.AbortReasonID = 0 THEN 1 ELSE 0 END) / @LiveSites) / @WeekCount * 52 END AS CallsPerSiteAnnual,
	   SUM(CASE WHEN Calls.AbortReasonID IN (1, 2, 4, 5) AND InvoicedOn IS NOT NULL THEN 1 ELSE 0 END) AS TotalAborts,
	   CASE WHEN SUM(CASE WHEN InvoicedOn IS NOT NULL THEN 1 ELSE 0 END) = 0 THEN 0 ELSE SUM(CASE WHEN Calls.AbortReasonID IN (1, 2, 4, 5) AND InvoicedOn IS NOT NULL THEN 1 ELSE 0 END) / CAST(SUM(CASE WHEN InvoicedOn IS NOT NULL THEN 1 ELSE 0 END) AS FLOAT) END AS OverallCallsAborted,
	   CASE WHEN SUM(CASE WHEN Calls.AbortReasonID IN (1, 2, 4, 5) AND InvoicedOn IS NOT NULL THEN 1 ELSE 0 END) = 0 THEN 0 ELSE SUM(CASE WHEN Calls.AbortReasonID IN (1, 2, 4, 5) AND ChargeableCalls.IsChargeable = 1 AND InvoicedOn IS NOT NULL THEN 1 ELSE 0 END) / CAST(SUM(CASE WHEN Calls.AbortReasonID IN (1, 2, 4, 5) AND InvoicedOn IS NOT NULL THEN 1 ELSE 0 END) AS FLOAT) END AS AbortedCallsChargeable,
	   SUM(CASE WHEN Calls.AbortReasonID = 0 AND ChargeableCalls.IsChargeable = 1 AND InvoicedOn IS NOT NULL THEN 1 ELSE 0 END) AS ChargeableNonAborted,
	   CASE WHEN SUM(CASE WHEN Calls.AbortReasonID = 0 AND InvoicedOn IS NOT NULL THEN 1 ELSE 0 END) = 0 THEN 0 ELSE SUM(CASE WHEN Calls.AbortReasonID = 0 AND ChargeableCalls.IsChargeable = 1 AND InvoicedOn IS NOT NULL THEN 1 ELSE 0 END) / CAST(SUM(CASE WHEN Calls.AbortReasonID = 0 AND InvoicedOn IS NOT NULL THEN 1 ELSE 0 END) AS FLOAT) END AS ChargeableFromTotal,
	   CASE WHEN @LiveSites = 0 THEN 0 ELSE (((SUM(CASE WHEN Calls.AbortReasonID = 0 AND InvoicedOn IS NOT NULL THEN 1 ELSE 0 END) - SUM(CASE WHEN Calls.AbortReasonID = 0 AND ChargeableCalls.IsChargeable = 1 AND InvoicedOn IS NOT NULL THEN 1 ELSE 0 END)) / @LiveSites) / @WeekCount) * 52 END AS ContractedCallsAnnual,
	   SUM(CASE WHEN InvoicedOn IS NOT NULL THEN CallCharges.TotalCharges ELSE 0 END) AS TotalCharges,
	   SUM(CASE WHEN InvoicedOn IS NOT NULL THEN CallCharges.EquipmentCharges ELSE 0 END) AS EquipmentCharges,
	   SUM(CASE WHEN InvoicedOn IS NOT NULL THEN CallCharges.LabourCharges ELSE 0 END) AS LabourCharges,
	   CASE WHEN SUM(CASE WHEN Calls.AbortReasonID = 0 AND ChargeableCalls.IsChargeable = 1 AND InvoicedOn IS NOT NULL THEN 1 ELSE 0 END) = 0 THEN 0 ELSE SUM(CASE WHEN ChargeableCalls.IsChargeable = 1 AND InvoicedOn IS NOT NULL THEN TotalCharges ELSE 0 END) / SUM(CASE WHEN Calls.AbortReasonID = 0 AND ChargeableCalls.IsChargeable = 1 AND InvoicedOn IS NOT NULL THEN 1 ELSE 0 END) END AS AvgChargePerChargeableCall,
	   SUM(CASE WHEN Calls.NumberOfVisits = 1 THEN 1 ELSE 0 END) AS CallsFirstTime,
	   CASE WHEN COUNT(Calls.[ID]) = 0 THEN 0 ELSE SUM(CASE WHEN Calls.NumberOfVisits = 1 THEN 1 ELSE 0 END) / CAST(COUNT(Calls.[ID]) AS FLOAT) END PercentFirstTime,
	   SUM(CASE WHEN Calls.PlanningIssueID = 1 THEN 1 ELSE 0 END) AS CallsNoIssue,
	   CASE WHEN SUM(CASE WHEN Calls.PlanningIssueID = 1 THEN 1 ELSE 0 END) = 0 THEN 0 ELSE SUM(CASE WHEN Calls.CallWithinSLA = 1 THEN 1 ELSE 0 END) / CAST(SUM(CASE WHEN Calls.PlanningIssueID = 1 THEN 1 ELSE 0 END) AS FLOAT) END AS InSLA,
	   SUM(CASE WHEN Calls.CallWithinSLA = 1 THEN 1 ELSE 0 END) AS CallsInSLACount,
	   SUM(CASE WHEN Calls.PriorityID = 2 THEN 1 ELSE 0 END) AS PriorityCalls,
	   CASE WHEN SUM(CASE WHEN Calls.PriorityID = 2 THEN 1 ELSE 0 END) = 0 THEN 0 ELSE SUM(CASE WHEN Calls.CallWithinSLA = 1 AND Calls.PriorityID = 2 THEN 1 ELSE 0 END) / CAST(SUM(CASE WHEN Calls.PriorityID = 2 THEN 1 ELSE 0 END) AS FLOAT) END AS PriorityCallsInSLA,
   	   SUM(CASE WHEN Calls.CallWithinSLA = 1 AND Calls.PriorityID = 2 THEN 1 ELSE 0 END) AS PriorityCallsInSLACount,
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
FROM CallsSLA AS Calls
JOIN @ChargeableCalls AS ChargeableCalls ON ChargeableCalls.CallID = Calls.[ID]
JOIN @CallCharges AS CallCharges ON CallCharges.CallID = Calls.[ID]
WHERE Calls.AbortReasonID <> 3
AND Calls.CallCategoryID NOT IN (2, 3, 4, 7)
AND Calls.[ID] NOT IN
(
	SELECT Calls.ID 
	FROM CallsSLA AS Calls
	JOIN CallFaults ON CallFaults.CallID = Calls.[ID]
	JOIN [EDISSQL1\SQL1].ServiceLogger.dbo.CallFaultTypes AS CallFaultTypes ON CallFaultTypes.[ID] = CallFaults.FaultTypeID
	WHERE ExcludeFromReporting = 1
)

DROP TABLE #DefaultItemPrices

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetCallSLAChargingReport] TO PUBLIC
    AS [dbo];

