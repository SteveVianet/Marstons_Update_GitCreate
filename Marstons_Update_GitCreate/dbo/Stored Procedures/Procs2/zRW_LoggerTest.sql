CREATE PROCEDURE [dbo].[zRW_LoggerTest] AS

DECLARE	@From		DATETIME = '2012-04-28'
DECLARE	@To			DATETIME = '2012-06-01'

SET NOCOUNT ON
							
CREATE TABLE #DefaultItemPrices ([ID] INT,
								 ItemPriority INT,
								 [Description] VARCHAR(50),
								 DefaultPrice MONEY,
								 Depreciated BIT,
								 [Type] VARCHAR(20))

CREATE TABLE #ChargeableCalls(CallID INT, IsChargeable BIT)
CREATE TABLE #CallCharges(CallID INT, TotalCharges FLOAT, EquipmentCharges FLOAT, LabourCharges FLOAT)

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

INSERT INTO #ChargeableCalls
SELECT [ID], IsChargeable
FROM Calls
WHERE ClosedOn BETWEEN @From AND DATEADD(SECOND, -1, DATEADD(DAY, 1, @To))

INSERT INTO #CallCharges
SELECT Calls.[ID],
	   SUM(CASE WHEN Calls.IsChargeable = 1 THEN InvoiceItems.Cost ELSE 0 END) AS TotalCharges,
	   SUM(CASE WHEN DefaultItemPrices.[Type] = 'Equipment' AND Calls.IsChargeable = 1 THEN InvoiceItems.Cost ELSE 0 END) AS EquipmentCharges,
	   SUM(CASE WHEN DefaultItemPrices.[Type] = 'Labour' AND Calls.IsChargeable = 1 THEN InvoiceItems.Cost ELSE 0 END) AS LabourCharges
FROM CallsSLA AS Calls
LEFT JOIN InvoiceItems ON InvoiceItems.CallID = Calls.[ID]
LEFT JOIN #DefaultItemPrices AS DefaultItemPrices ON DefaultItemPrices.[ID] = InvoiceItems.ItemID
GROUP BY Calls.[ID]

SELECT  @CompanyName AS Company,
		dbo.GetCallReference(Calls.ID) AS CallReference,
	   Sites.SiteID,
	   Sites.Name,
	   Sites.PostCode,
	   COALESCE(Cont.Description, '<None>') AS ContractName,
	   Calls.RaisedOn,
	   Calls.ClosedOn,
	   Calls.InvoicedOn,
	   Calls.AbortDate,
		CAST(CASE WHEN InvoicedOn IS NOT NULL THEN 1 ELSE 0 END AS BIT) AS Invoiced,
		CAST(CASE WHEN AbortReasonID IN (1, 2, 4, 5) THEN 1 ELSE 0 END AS BIT) AS Aborted,
		ChargeableCalls.IsChargeable,
	   CASE WHEN InvoicedOn IS NOT NULL THEN COALESCE(CallCharges.TotalCharges,0) ELSE 0 END AS TotalCharges,
	   CASE WHEN InvoicedOn IS NOT NULL THEN COALESCE(CallCharges.EquipmentCharges,0) ELSE 0 END AS EquipmentCharges,
	   CASE WHEN InvoicedOn IS NOT NULL THEN COALESCE(CallCharges.LabourCharges,0) ELSE 0 END AS LabourCharges,
	   COALESCE(Costs.FullCostPrice,0) AS FullCostPrice,
	   COALESCE(Costs.FullRetailPrice,0) AS FullRetailPrice,
	   COALESCE(Costs.LabourMinutes,0) AS LabourMinutes,
	   COALESCE(Costs.FullCostPriceCharged,0) AS FullCostPriceCharged,
	   COALESCE(Costs.FullRetailPriceCharged,0) AS FullRetailPriceCharged,
	   COALESCE(Costs.LabourMinutesCharged,0) AS LabourMinutesCharged,
	   StandardLabourCharge,
	   AdditionalLabourCharge
	   --CallCategories.[Description] AS CallCategory
FROM CallsSLA AS Calls
JOIN #ChargeableCalls AS ChargeableCalls ON ChargeableCalls.CallID = Calls.[ID]
JOIN #CallCharges AS CallCharges ON CallCharges.CallID = Calls.[ID]
JOIN Sites ON Sites.EDISID = Calls.EDISID
--LEFT JOIN [EDISSQL1\SQL1].ServiceLogger.dbo.CallCategories AS CallCategories ON CallCategories.[ID] = Calls.CallCategoryID
LEFT JOIN (
	SELECT SiteContracts.EDISID, Contracts.Description
	FROM SiteContracts
	JOIN Contracts ON Contracts.ID = SiteContracts.ContractID
) AS Cont ON Cont.EDISID = Sites.EDISID
LEFT JOIN (
	SELECT  CallID,
			SUM(CASE WHEN IsCharged = 0 THEN FullCostPrice ELSE 0 END) AS FullCostPrice,
			SUM(CASE WHEN IsCharged = 0 THEN FullRetailPrice ELSE 0 END) AS FullRetailPrice,
			SUM(CASE WHEN IsCharged = 0 THEN LabourMinutes ELSE 0 END) AS LabourMinutes,
			SUM(CASE WHEN IsCharged = 1 THEN FullCostPrice ELSE 0 END) AS FullCostPriceCharged,
			SUM(CASE WHEN IsCharged = 1 THEN FullRetailPrice ELSE 0 END) AS FullRetailPriceCharged,
			SUM(CASE WHEN IsCharged = 1 THEN LabourMinutes ELSE 0 END) AS LabourMinutesCharged
	FROM CallBillingItems
	GROUP BY CallID
) AS Costs ON Costs.CallID = Calls.ID
WHERE Calls.AbortReasonID <> 3

DROP TABLE #DefaultItemPrices
DROP TABLE #ChargeableCalls
DROP TABLE #CallCharges
