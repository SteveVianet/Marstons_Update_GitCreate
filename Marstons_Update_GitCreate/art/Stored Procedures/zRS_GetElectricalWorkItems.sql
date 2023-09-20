CREATE PROCEDURE [art].[zRS_GetElectricalWorkItems]
(
	@From					DATETIME,
	@To						DATETIME
)
AS

/* Returns specific list of electrical billing items between date range */
/* Amend ID's in WHERE clause to include/remove additional billing items */

SELECT
	Calls.ID
	,e.Name EngineerName
	,le.Name LeadEngineerName
	,DB_NAME() AS DbName
	,S.SiteID
	,CO.Description AS 'Contract'
	,S.Name
	,S.Address3
	,S.PostCode
	,(CASE WHEN CO.Type = 1 THEN 'BMS' WHEN CO.Type =2 THEN 'iDraught' END ) AS 'Product'
	,dbo.GetCallReference(dbo.Calls.ID) AS Callref
	,CBI.Quantity
	,(CASE WHEN  Calls.QualitySite = 1 THEN BI.IDraughtPartCost * CBI.Quantity
		   WHEN  Calls.QualitySite = 0 THEN BI.BMSPartCost *  CBI.Quantity ELSE 0 END) AS 'TotalPartsCost'
	,Calls.VisitedOn
	,Calls.[ClosedOn]
	,BI.Description AS 'Item'
	,BIC.Description AS 'ItemType'
	,cwdc.WorkDetailComment
FROM
	[dbo].[Calls]
INNER JOIN
	CallBillingItems AS CBI ON Calls.ID = CBI.CallID
INNER JOIN
	Sites AS S ON Calls.EDISID = S.EDISID
INNER JOIN
	[SQL1\SQL1].[ServiceLogger].[dbo].[BillingItems] AS BI ON CBI.BillingItemID = BI.ID
INNER JOIN
	[SQL1\SQL1].[ServiceLogger].[dbo].[BillingItemCategory] AS BIC ON BI.CategoryID = BIC.ID
INNER JOIN
	[SQL1\SQL1].[ServiceLogger].[dbo].[BillingItemType] AS BLIT ON BI.ItemType = BLIT.ID
INNER JOIN
	[SQL1\SQL1].[ServiceLogger].[dbo].[ContractorEngineers] AS e ON e.ID = Calls.EngineerID
INNER JOIN
	[SQL1\SQL1].[ServiceLogger].[dbo].[ContractorEngineers] AS le ON le.ID = e.LeadEngineerID
INNER JOIN
	SiteContracts AS SC ON S.EDISID = SC.EDISID
INNER JOIN
	Contracts AS CO ON Calls.ContractID = CO.ID
INNER JOIN
	[SQL1\SQL1].[ServiceLogger].[dbo].CallChargeReasons AS CCR ON Calls.ChargeReasonID = CCR.ID
INNER JOIN
	CallWorkDetailComments cwdc ON cwdc.CallID = Calls.ID

WHERE Calls.[ClosedOn] BETWEEN @From AND @To
AND BI.ID IN (24,25,26,27,68,82,107,109,110,111,113,149,154)
GO
GRANT EXECUTE
    ON OBJECT::[art].[zRS_GetElectricalWorkItems] TO PUBLIC
    AS [dbo];

