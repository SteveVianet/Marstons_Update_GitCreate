CREATE PROCEDURE [dbo].[zRS_EngineersStockUsage]


( 
@StartDate DATETIME= NULL,
@EndDate DATETIME=  NULL,
@EngineerID INT = NULL
)

AS

SET NOCOUNT ON

/****** Report to look at the cost of all items selected by engineers - brings back each item then based on system type looks at the master work items 
and the associated cost of that item - flag is quality (this will need to be amended if new products created_  ******/

SELECT 
DB_NAME() AS Customer,
       CE.Name 
      ,CBI.BillingItemID
      ,CBI.Quantity
      ,Calls.QualitySite
      ,(CASE WHEN  Calls.QualitySite = 1 
            THEN BI.IDraughtPartCost * CBI.Quantity
            WHEN  Calls.QualitySite = 0 THEN BI.BMSPartCost *  CBI.Quantity ELSE 0 END) AS 'PartsCost'
      ,Calls.ID  
      ,Calls.[ClosedOn]    
      ,Calls.[InvoicedOn]
      ,BI.Description
      ,BIC.Description
      ,BLIT.Description

  FROM [dbo].[Calls]
  INNER JOIN [SQL1\SQL1].[ServiceLogger].[dbo].[ContractorEngineers] AS CE ON Calls.EngineerID = CE.ID
  INNER JOIN CallBillingItems AS CBI ON Calls.ID = CBI.CallID
  INNER JOIN [SQL1\SQL1].[ServiceLogger].[dbo].[BillingItems] AS BI ON CBI.BillingItemID = BI.ID
  INNER JOIN [SQL1\SQL1].[ServiceLogger].[dbo].[BillingItemCategory] AS BIC ON BI.CategoryID = BIC.ID
  INNER JOIN [SQL1\SQL1].[ServiceLogger].[dbo].[BillingItemType] AS BLIT ON BI.ItemType = BLIT.ID
 
  WHERE UseBillingItems =1 And InvoicedOn IS NOT NULL AND ClosedOn BETWEEN  @StartDate AND DATEADD(SECOND, -1, DATEADD(DAY, 1, @EndDate)) AND (Calls.EngineerID = @EngineerID OR @EngineerID IS NULL)

--(CASE WHEN  Calls.QualitySite = 1 
--            THEN BI.IDraughtPartCost * CBI.Quantity
--            WHEN  Calls.QualitySite = 0 THEN BI.BMSPartCost *  CBI.Quantity ELSE 0 END) >0
 
  AND  BLIT.Description NOT IN ('Internal','Observation','Deadtime')
  Order BY Calls.ID;
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[zRS_EngineersStockUsage] TO PUBLIC
    AS [dbo];

