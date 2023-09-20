CREATE PROCEDURE [dbo].[zRS_JobsWithCosts]

--this looks at all calls and all billing items in that call - it uses the cost of the items from the master billing items table - so all costs are as of now

--the labour is based on the estimated timings x by the parameter


(
@StartDate DATETIME= NULL,
@EndDate DATETIME=  NULL,
@EngineerID INT = NULL,
@EngineerLabourCostPH   MONEY = 0,
@IncludeStandardcalls BIT = 0 ,
@IncludeElectrical    BIT = 0,
@IncludeInstall       BIT = 0,
@IncludeInternal      BIT = 0 ,
@IncludeMaintenance   BIT = 0 ,
@IncludeReInstall     BIT = 0 ,
@IncludeUpgrade       BIT = 0 ,
@IncludeUplift        BIT = 0,
@IncludeThirdParty    BIT = 0

)
AS



BEGIN

       -- SET NOCOUNT ON added to prevent extra result sets from
       -- interfering with SELECT statements.

       SET NOCOUNT ON;

    -- Insert statements for procedure here

SELECT

DB_NAME() AS Customer
    ,S.SiteID
    ,CO.Description AS 'Contract'
    ,S.Name
    ,S.Address3
   ,dbo.GetCallReference(dbo.Calls.ID) AS Callref
      ,CBI.Quantity
      ,(CASE WHEN  Calls.QualitySite = 1
            THEN BI.IDraughtPartCost * CBI.Quantity
            WHEN  Calls.QualitySite = 0 THEN BI.BMSPartCost *  CBI.Quantity ELSE 0 END) AS 'TotalPartsCost'

      ,Calls.[ClosedOn]
      ,Calls.[InvoicedOn]
      ,BI.Description AS 'Item'
      ,BIC.Description AS 'ItemType'
   ,CCR.Description AS 'Chargereason'
   ,(CASE WHEN CO.Type = 1 THEN 'BMS' WHEN CO.Type =2 THEN 'iDraught'  END ) AS 'Product'

   ,(CASE WHEN Calls.InvoicedOn IS NOT NULL  AND Calls.QualitySite = 1
            THEN BI.IDraughtLabourBy5Minutes WHEN Calls.InvoicedOn IS NOT NULL
            AND Calls.QualitySite = 0 THEN BI.BMSLabourBy5Minutes ELSE 0 END)  * CBI.Quantity AS EstLabourMinutes

   ,(CASE WHEN Calls.InvoicedOn IS NOT NULL  AND Calls.QualitySite = 1
            THEN BI.IDraughtLabourBy5Minutes WHEN Calls.InvoicedOn IS NOT NULL
            AND Calls.QualitySite = 0 THEN BI.BMSLabourBy5Minutes ELSE 0 END)* CBI.Quantity/60 * @EngineerLabourCostPH AS EstLabourCost

  FROM [dbo].[Calls]

 INNER JOIN CallBillingItems AS CBI ON Calls.ID = CBI.CallID
 INNER JOIN Sites AS S ON Calls.EDISID = S.EDISID
 INNER JOIN [SQL1\SQL1].[ServiceLogger].[dbo].[BillingItems] AS BI ON CBI.BillingItemID = BI.ID
 INNER JOIN [SQL1\SQL1].[ServiceLogger].[dbo].[BillingItemCategory] AS BIC ON BI.CategoryID = BIC.ID
 INNER JOIN [SQL1\SQL1].[ServiceLogger].[dbo].[BillingItemType] AS BLIT ON BI.ItemType = BLIT.ID
 INNER JOIN SiteContracts AS SC ON S.EDISID = SC.EDISID
 INNER JOIN Contracts AS CO ON Calls.ContractID = CO.ID
 INNER JOIN  [SQL1\SQL1].[ServiceLogger].[dbo].CallChargeReasons AS CCR ON Calls.ChargeReasonID = CCR.ID

  WHERE Calls.UseBillingItems =1 And InvoicedOn IS NOT NULL AND ClosedOn BETWEEN  @StartDate AND DATEADD(SECOND, -1, DATEADD(DAY, 1, @EndDate))  AND (Calls.EngineerID = @EngineerID OR @EngineerID IS NULL) AND Calls.AbortReasonID <> 3

AND

(CASE WHEN  Calls.QualitySite = 1
            THEN BI.IDraughtPartCost * CBI.Quantity
            WHEN  Calls.QualitySite = 0 THEN BI.BMSPartCost *  CBI.Quantity ELSE 0 END) >=0

AND  BLIT.Description NOT IN ('Observation','Deadtime')
AND ((Calls.CallCategoryID = 1 AND @IncludeStandardcalls = 1)
OR (Calls.CallCategoryID = 5 AND @IncludeElectrical = 1)
OR (Calls.CallCategoryID = 4 AND @IncludeInstall = 1)
OR (Calls.CallCategoryID = 3 AND @IncludeInternal = 1)
OR (Calls.CallCategoryID = 2 AND @IncludeMaintenance = 1)
OR (Calls.CallCategoryID = 6 AND @IncludeReInstall = 1)
OR (Calls.CallCategoryID = 9 AND @IncludeUpgrade = 1)
OR (Calls.CallCategoryID = 10 AND @IncludeUplift = 1)
OR (Calls.CallCategoryID = 7 AND @IncludeThirdParty = 1))

END


--SELECT *
--From Calls
--WHERE Calls.ID = '23083'

--SELECT *
--From CallBillingItems
--WHERE CallBillingItems.CallID = '23083'
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[zRS_JobsWithCosts] TO PUBLIC
    AS [dbo];

