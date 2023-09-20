
CREATE PROCEDURE [dbo].[GetContractCostReport]
(
      @From       DATETIME,
      @To               DATETIME,
      @EngineerLabourCostPH   MONEY,
      @ServicePackIncomePerWeek MONEY,
      @IncludeStandardcalls BIT = 0,
      @IncludeElectrical    BIT = 0,
      @IncludeInstall       BIT = 0,
      @IncludeInternal      BIT = 0,
      @IncludeMaintenance   BIT = 0,
      @IncludeReInstall     BIT = 0,
      @IncludeUpgrade       BIT = 0,
      @IncludeUplift        BIT = 0,
      @IncludeThirdParty    BIT = 0
)
AS

SET NOCOUNT ON

DECLARE @WeekCount FLOAT

SET @WeekCount = DATEDIFF(week, @From , @To)
--SET @EngineerLabourCostPH = 45
--SET @ServicePackIncomePerWeek = 3.0

SELECT  DB_NAME() AS Customer,
            Contracts.[Description],
           Contracts.Type,
            LiveSites.LiveSites,
              --Count of sites in contract,
           -- CASE WHEN CallsSLA.CallTypeID = 1 THEN 'Service Call' ELSE 'Install' END AS CallType,
          --  CallsSLA.CallCategoryID AS CallCategory,
                  --CASE WHEN CallsSLA.IsChargeable  =  1 THEN 'Charged' ELSE 'Contracted' END AS Charged,
           --Use this flag to split the charged or no charged jobs into a group
            COUNT(CallsSLA.[ID]) AS TotalJobsCompleted,
            --Invoiced on refers to having been checked by finance
            SUM(CASE WHEN CallsSLA.InvoicedOn IS NOT NULL THEN 1 ELSE 0 END) AS CheckedByFinance,
            SUM(CASE WHEN CallsSLA.InvoicedOn IS NOT NULL THEN 1 ELSE 0 END) / CASE WHEN COUNT(CallsSLA.[ID]) = 0 THEN 1.0 
            ELSE CAST(COUNT(CallsSLA.[ID]) AS FLOAT) END AS PercentChecked,
            SUM(CASE WHEN CallsSLA.InvoicedOn IS NOT NULL AND AbortReasonID = 0 THEN 1 ELSE 0 END) AS CallsCheckedExcludingAborted,
            SUM(CASE WHEN CallsSLA.InvoicedOn IS NOT NULL AND CallsSLA.IsChargeable = 0 THEN 1 ELSE 0 END) AS ContractCalls,
            --If the mark as invoiced flag (is chargeable) is set to 0 then the job has not been charged outside contract and is deemed to be a contract call
            
            SUM(CASE WHEN CallsSLA.InvoicedOn IS NOT NULL AND CallsSLA.IsChargeable = 0 THEN 1.0 ELSE 0 END)
           / CASE WHEN SUM(CASE WHEN CallsSLA.InvoicedOn IS NOT NULL AND AbortReasonID = 0 THEN 1.0 ELSE 0 END) = 0 
             THEN 1.0 ELSE SUM(CASE WHEN CallsSLA.InvoicedOn IS NOT NULL AND AbortReasonID = 0 THEN 1.0 ELSE 0 END) END AS PercentContractCalls,
            
         

            (SUM(CASE WHEN CallsSLA.InvoicedOn IS NOT NULL  THEN 1.0 ELSE 0 END)
            / CAST(CASE WHEN LiveSites.LiveSites = 0 THEN 1 ELSE LiveSites.LiveSites END AS FLOAT)) 
             / CASE WHEN @WeekCount = 0 THEN 1 ELSE @WeekCount END * 52.0 AS Callsperyrpersite,
            --Add up all checked jobs / Sites in contract/weeks your looking at * 52
            (SUM(CASE WHEN CallsSLA.InvoicedOn IS NOT NULL AND CallsSLA.IsChargeable  = 0 THEN 1.0 ELSE 0 END)
            / CAST(CASE WHEN LiveSites.LiveSites = 0 THEN 1 ELSE LiveSites.LiveSites END AS FLOAT)) 
             / CASE WHEN @WeekCount = 0 THEN 1 ELSE @WeekCount END * 52.0 AS EstContractCallsPA,
            --Look at all the contract calls and work out how many per year
            
            SUM(CASE WHEN CallsSLA.InvoicedOn IS NOT NULL AND CallsSLA.QualitySite = 1 
            THEN BillingItems.IDraughtPartCost 
            WHEN CallsSLA.InvoicedOn IS NOT NULL 
            AND CallsSLA.QualitySite = 0 THEN BillingItems.BMSPartCost ELSE 0 END) AS TotalPartsCost,
            --looks at all jobs to see what the total cost of the parts is
            
            
            SUM(CASE WHEN CallsSLA.InvoicedOn IS NOT NULL THEN BillingItems.LabourEstMinutes ELSE 0 END) AS EstLabourMinutes,
            --looks at all jobs to see what the total estimated labour time is
            
            SUM(CASE WHEN CallsSLA.InvoicedOn IS NOT NULL THEN BillingItems.LabourEstMinutes ELSE 0 END) /60 * @EngineerLabourCostPH AS EstLabourCost,
            --Multiple the times by the applied cash values.
     
     
 ---same section but to look at the costs of the Invoiced calls only  
      
            SUM(CASE WHEN CallsSLA.InvoicedOn IS NOT NULL AND CallsSLA.QualitySite = 1 AND CallsSLA.IsChargeable = 1 
            THEN BillingItems.IDraughtPartCost 
            WHEN CallsSLA.InvoicedOn IS NOT NULL 
            AND CallsSLA.QualitySite = 0 AND CallsSLA.IsChargeable = 1 THEN BillingItems.BMSPartCost ELSE 0 END) AS TotalPartsCostCharged,
            --looks at all jobs to see what the total cost of the parts are for charged calls
            
            
            SUM(CASE WHEN CallsSLA.InvoicedOn IS NOT NULL AND CallsSLA.IsChargeable = 1
            THEN BillingItems.LabourEstMinutes ELSE 0 END) AS EstLabourMinutesCharged,
            --looks at all jobs to see what the total estimated labour time are for charged calls
            
            SUM(CASE WHEN CallsSLA.InvoicedOn IS NOT NULL AND CallsSLA.IsChargeable = 1
            THEN BillingItems.LabourEstMinutes ELSE 0 END) /60 * @EngineerLabourCostPH AS EstLabourCostCharged,
            --Multiple the times by the applied cash values for charged calls
            
            
            SUM(LiveSites.LiveSites * @ServicePackIncomePerWeek * @WeekCount) AS ContractIncomeInperiod,
            --multiply the sites by the user entered service pack and then multiply by the numbers of weeks looking at
      
            
            SUM(CASE WHEN CallsSLA.InvoicedOn IS NOT NULL AND  AbortReasonID = 0 AND CallsSLA.IsChargeable = 1 THEN 1 ELSE 0 END) AS ChargeableCallsnotaborts,
            
            
            SUM(CASE WHEN CallsSLA.InvoicedOn IS NOT NULL AND  AbortReasonID = 0 AND CallsSLA.IsChargeable = 1 THEN 1.0 ELSE 0 END) / CASE WHEN
            SUM(CASE WHEN CallsSLA.InvoicedOn IS NOT NULL AND AbortReasonID = 0 THEN 1.0 ELSE 0 END) = 0 THEN 1.0 ELSE 
             SUM(CASE WHEN CallsSLA.InvoicedOn IS NOT NULL AND AbortReasonID = 0 THEN 1.0 ELSE 0 END) END AS PercentChargableCalls,
            
            (SUM(CASE WHEN CallsSLA.InvoicedOn IS NOT NULL AND AbortReasonID = 0 AND CallsSLA.IsChargeable  = 1 THEN 1.0 ELSE 0 END) / CAST(CASE WHEN LiveSites.LiveSites = 0 
            THEN 1 ELSE LiveSites.LiveSites END AS FLOAT)) / CASE WHEN @WeekCount = 0 THEN 1 ELSE @WeekCount END * 52.0 AS EstChargeableCallsPA,
            
            
            SUM(CASE WHEN CallsSLA.IsChargeable = 1  AND AbortReasonID = 0 THEN BillingItems.FullRetailPrice + CallsSLA.StandardLabourCharge + CallsSLA.AdditionalLabourCharge ELSE 0 END) AS TotalinvoicedNet,
            
                  
            
            
            
      
            
            (SUM(CASE WHEN CallsSLA.IsChargeable = 1 THEN BillingItems.FullRetailPrice + CallsSLA.StandardLabourCharge + CallsSLA.AdditionalLabourCharge ELSE 0 END)) / 
            (CASE WHEN SUM(CASE WHEN CallsSLA.InvoicedOn IS NOT NULL AND  AbortReasonID = 0 AND CallsSLA.IsChargeable = 1 THEN 1 ELSE 0 END)
            = 0 THEN 1 ELSE SUM(CASE WHEN CallsSLA.InvoicedOn IS NOT NULL AND  AbortReasonID = 0 AND CallsSLA.IsChargeable = 1 THEN 1 ELSE 0 END) END) AS AvgInvoiceNetnotabort,
            
            SUM(CASE WHEN CallsSLA.AbortReasonID > 0 THEN 1 ELSE 0 END) AS Aborts,
            SUM(CASE WHEN CallsSLA.AbortReasonID > 0 THEN 1.0 ELSE 0 END) / CASE WHEN COUNT(CallsSLA.[ID]) = 0 THEN 1 ELSE COUNT(CallsSLA.[ID]) END AS PercentCallsAborted,
            SUM(CASE WHEN CallsSLA.AbortReasonID > 0 AND CallsSLA.IsChargeable = 1 THEN 1 ELSE 0 END) AS AbortsChargedOn,
            SUM(CASE WHEN CallsSLA.AbortReasonID > 0 AND CallsSLA.IsChargeable = 1 THEN 1.0 ELSE 0 END) / CASE WHEN SUM(CASE WHEN CallsSLA.AbortReasonID > 0 THEN 1.0 ELSE 0 END)
            = 0 THEN 1.0 ELSE SUM(CASE WHEN CallsSLA.AbortReasonID > 0 THEN 1.0 ELSE 0 END) END AS PercentAbortedChargeable,
            
            SUM(CASE WHEN CallsSLA.AbortReasonID > 0 AND CallsSLA.IsChargeable = 1 THEN BillingItems.FullRetailPrice ELSE 0 END) AS TotalAbortCharges,
            SUM(CASE WHEN CallsSLA.AbortReasonID > 0 AND CallsSLA.IsChargeable = 1 THEN BillingItems.FullRetailPrice ELSE 0 END) / 
            CASE WHEN SUM(CASE WHEN CallsSLA.AbortReasonID > 0 AND CallsSLA.IsChargeable = 1 THEN 1.0 ELSE 0 END) = 0 THEN 1.0 ELSE 
            SUM(CASE WHEN CallsSLA.AbortReasonID > 0 AND CallsSLA.IsChargeable = 1 THEN 1.0 ELSE 0 END) END AS AvgAmountBilledAborts



FROM CallsSLA


JOIN SiteContracts ON SiteContracts.EDISID = CallsSLA.EDISID

JOIN Contracts ON Contracts.[ID] = CallsSLA.ContractID

JOIN (      
            SELECT ContractID, COUNT(SiteContracts.EDISID) AS LiveSites
            FROM SiteContracts
            JOIN Sites ON Sites.EDISID = SiteContracts.EDISID
            WHERE Hidden = 0
            GROUP BY ContractID
) AS LiveSites ON LiveSites.ContractID = Contracts.[ID]
JOIN Sites ON Sites.EDISID = CallsSLA.EDISID
JOIN Owners ON Owners.[ID] = Sites.OwnerID

LEFT JOIN ( SELECT CallID,
                              SUM(BillingItems.BMSPartCost * CallBillingItems.Quantity) AS BMSPartCost,
                              SUM(BillingItems.IDraughtPartCost * CallBillingItems.Quantity) AS IDraughtPartCost,
							  SUM(LabourMinutes) AS LabourEstMinutes,
                              SUM(FullRetailPrice) AS FullRetailPrice
                  FROM CallBillingItems
                  JOIN [EDISSQL1\SQL1].ServiceLogger.dbo.BillingItems AS BillingItems ON BillingItems.[ID] = CallBillingItems.BillingItemID
                  WHERE ItemType In (1,3,4)
                  GROUP BY CallID
) AS BillingItems ON BillingItems.CallID = CallsSLA.[ID]

WHERE ClosedOn BETWEEN @From AND DATEADD(SECOND, -1, DATEADD(DAY, 1, @To))
AND CallsSLA.AbortReasonID <> 3

--We may at somepoint choose to exlude some calls based on the types
AND ((CallsSLA.CallCategoryID = 1 AND @IncludeStandardcalls = 1)
OR (CallsSLA.CallCategoryID = 5 AND @IncludeElectrical = 1)
OR (CallsSLA.CallCategoryID = 4 AND @IncludeInstall = 1)
OR (CallsSLA.CallCategoryID = 3 AND @IncludeInternal = 1)
OR (CallsSLA.CallCategoryID = 2 AND @IncludeMaintenance = 1)
OR (CallsSLA.CallCategoryID = 6 AND @IncludeReInstall = 1)
OR (CallsSLA.CallCategoryID = 9 AND @IncludeUpgrade = 1)
OR (CallsSLA.CallCategoryID = 10 AND @IncludeUplift = 1)
OR (CallsSLA.CallCategoryID = 7 AND @IncludeThirdParty = 1))

GROUP BY 
            
            Contracts.[Description],
            Contracts.Type,
         -- CASE WHEN CallsSLA.CallTypeID = 1 THEN 'Service Call' ELSE 'Install' END,
            --CASE WHEN CallsSLA.IsChargeable  =  1 THEN 'Charged' ELSE 'Contracted' END,
          --  CallsSLA.CallCategoryID, 
            LiveSites.LiveSites

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetContractCostReport] TO PUBLIC
    AS [dbo];

