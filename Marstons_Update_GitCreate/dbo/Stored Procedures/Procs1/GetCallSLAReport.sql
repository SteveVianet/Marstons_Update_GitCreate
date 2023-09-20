CREATE PROCEDURE [dbo].[GetCallSLAReport]
(
	@From				DATETIME,
	@To					DATETIME,
	@CallTypeID			INT = NULL,
	@GroupOverride		VARCHAR(50) = NULL,
	@IncludeService		BIT = 1,
	@IncludeElectrical	BIT = 1,
	@IncludeInstall		BIT = 0,
	@IncludeInternal	BIT = 0,
	@IncludeMaintenance	BIT = 0,
	@IncludeReInstall	BIT = 1,
	@IncludeUpgrade		BIT = 1,
	@IncludeUplift		BIT = 1,
	@IncludeThirdParty	BIT = 1,
	@EngineerID			INT = NULL
)
AS

SET NOCOUNT ON
SET DATEFIRST 1

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
							
CREATE TABLE #ContractorEngineers([ID] INT, 
								[Name] VARCHAR(255),
								Mobile VARCHAR(255),
								Active BIT,
								LoginID INT,
								CoordinatorName VARCHAR(255),
								CoordinatorExtension VARCHAR(15),
								Address1 VARCHAR(255),
								Address2 VARCHAR(255),
								Address3 VARCHAR(255),
								Address4 VARCHAR(255),
								PostCode VARCHAR(15),
								HouseLongitude FLOAT,
								HouseLatitude FLOAT,
								HandheldIMEI VARCHAR(15))
							
CREATE TABLE #DefaultItemPrices ([ID] INT,
								 ItemPriority INT,
								 [Description] VARCHAR(50),
								 DefaultPrice MONEY,
								 Depreciated BIT,
								 [Type] VARCHAR(20))

DECLARE @CallSLAs TABLE(CallID INT, InSLA BIT, ExcludeFromSLA BIT)
DECLARE @CallCharges TABLE(CallID INT, TotalCharges FLOAT, EquipmentCharges FLOAT, LabourCharges FLOAT)
DECLARE @ReRaisedCalls TABLE(CallID INT)
DECLARE @SiteInfo TABLE(EDISID INT PRIMARY KEY, AllInclusive BIT, OldAge BIT, ContractID INT, Hidden BIT, [Description] VARCHAR(50))

DECLARE @CompanyName VARCHAR(100)

SELECT @CompanyName = CAST(PropertyValue AS VARCHAR)
FROM Configuration
WHERE PropertyName = 'Company Name'

INSERT INTO #CallFaultTypes
([ID], [Description], RequiresAdditionalInfo, MaxOccurences, PreventsDownload, ForceRequirePO, ForceNotRequirePO, DefaultEngineer, AdditionalInfoType, DisplayColour, WorkDetailDescription, Depreciated, CallType, SLA, Category, ExcludeFromReporting)
EXEC [EDISSQL1\SQL1].ServiceLogger.dbo.GetCallFaultTypes

INSERT INTO #ContractorEngineers
([ID], [Name], Mobile, Active, LoginID, CoordinatorName, CoordinatorExtension, Address1, Address2, Address3, Address4, PostCode, HouseLongitude, HouseLatitude, HandheldIMEI)
EXEC [EDISSQL1\SQL1].ServiceLogger.dbo.GetContractorEngineers 1

INSERT INTO #DefaultItemPrices
([ID], ItemPriority, [Description], DefaultPrice, Depreciated, [Type])
EXEC dbo.GetDefaultItemPrices

INSERT INTO @CallSLAs
SELECT [ID],
	   CallWithinSLA,
	   0
FROM CallsSLA
WHERE ClosedOn BETWEEN @From AND DATEADD(SECOND, -1, DATEADD(DAY, 1, @To))

--INSERT INTO @CallSLAs
--SELECT CallSLAs.[ID], 
--	   CASE WHEN (CASE WHEN ClosedOn IS NULL THEN dbo.fnGetWeekdayCount(RaisedOn, GETDATE()) ELSE dbo.fnGetWeekdayCount(RaisedOn, ClosedOn) END) > SLA THEN 0 ELSE 1 END AS InSLA, 
--	   0
--FROM
--(
--	SELECT	Calls.[ID],
--			Calls.RaisedOn,
--			Calls.ClosedOn,
--			MAX(CASE WHEN OverrideSLA > 0 THEN OverrideSLA
--				 WHEN CallTypeID = 2 AND SalesReference LIKE 'TRA%'	THEN 21
--				 WHEN CallTypeID = 2 AND SalesReference NOT LIKE 'TRA%'THEN 7
--				 ELSE COALESCE(CallFaults.SLA, CallFaultTypes.SLA, 0) END) AS SLA
--	FROM Calls
--	LEFT JOIN CallFaults ON CallFaults.CallID = Calls.[ID]
--	LEFT JOIN #CallFaultTypes AS CallFaultTypes ON CallFaultTypes.[ID] = CallFaults.FaultTypeID
--	WHERE ClosedOn BETWEEN @From AND DATEADD(SECOND, -1, DATEADD(DAY, 1, @To))
--	GROUP BY Calls.[ID], Calls.RaisedOn, Calls.ClosedOn
--) AS CallSLAs
--GROUP BY CallSLAs.[ID], CallSLAs.RaisedOn, CallSLAs.ClosedOn, CallSLAs.SLA

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
LEFT JOIN CallBillingItems ON CallBillingItems.CallID = Calls.[ID]
LEFT JOIN #DefaultItemPrices AS DefaultItemPrices ON DefaultItemPrices.[ID] = InvoiceItems.ItemID
GROUP BY Calls.[ID]

INSERT INTO @ReRaisedCalls
SELECT DISTINCT ReRaiseFromCallID
FROM
(
SELECT DISTINCT ReRaiseFromCallID
FROM Calls
WHERE ReRaiseFromCallID > 0
UNION ALL
SELECT [ID]
FROM Calls
WHERE ReRaiseFromCallID > 0
) AS ReRaisedCalls

INSERT INTO @SiteInfo (EDISID, AllInclusive, OldAge, ContractID, Hidden, [Description])
SELECT Sites.EDISID, AllInclusive, CASE WHEN DATEDIFF(Year, Sites.InstallationDate, GETDATE()) >= 5 THEN 1 ELSE 0 END, ContractID, Hidden, [Description]
FROM Sites
JOIN SiteContracts ON SiteContracts.EDISID = Sites.EDISID
JOIN Contracts ON Contracts.ID = SiteContracts.ContractID

SELECT	CASE WHEN @GroupOverride IS NOT NULL THEN @GroupOverride ELSE @CompanyName END AS Company,
		Calls.[ID] AS CallID,
		CallSLAs.InSLA,
		PriorityID,
	    AbortReasonID,
	    IsChargeable,
	    CASE WHEN InvoicedOn IS NOT NULL THEN 1 ELSE 0 END AS IsInvoiced,
	    PlanningIssueID,
	    CallCharges.EquipmentCharges,
	    CallCharges.LabourCharges,
	    CallCharges.TotalCharges,
	    CASE WHEN ReRaisedCalls.CallID IS NULL THEN 1 ELSE 0 END AS IsFirstTime,
	    ContractorEngineers.Name AS Engineer,
	    ContractorEngineers.LoginID AS Planner,
	    CASE WHEN SiteInfo.[Description] IS NULL THEN 'No Contract' ELSE [Description] END AS ContractDescription,
		ClosedOn,
		Calls.EngineerID
FROM Calls
JOIN @CallSLAs AS CallSLAs ON CallSLAs.CallID = Calls.[ID]
LEFT JOIN @CallCharges AS CallCharges ON CallCharges.CallID = Calls.[ID]
LEFT JOIN #ContractorEngineers AS ContractorEngineers ON ContractorEngineers.[ID] = Calls.EngineerID
LEFT JOIN @ReRaisedCalls AS ReRaisedCalls ON ReRaisedCalls.CallID = Calls.[ID]
LEFT JOIN @SiteInfo AS SiteInfo ON SiteInfo.EDISID = Calls.EDISID
WHERE Calls.AbortReasonID <> 3
AND (Calls.EngineerID = @EngineerID OR @EngineerID IS NULL)
AND ((Calls.CallCategoryID = 1 AND @IncludeService = 1)
OR (Calls.CallCategoryID = 5 AND @IncludeElectrical = 1)
OR (Calls.CallCategoryID = 4 AND @IncludeInstall = 1)
OR (Calls.CallCategoryID = 3 AND @IncludeInternal = 1)
OR (Calls.CallCategoryID = 2 AND @IncludeMaintenance = 1)
OR (Calls.CallCategoryID = 6 AND @IncludeReInstall = 1)
OR (Calls.CallCategoryID = 9 AND @IncludeUpgrade = 1)
OR (Calls.CallCategoryID = 10 AND @IncludeUplift = 1)
OR (Calls.CallCategoryID = 7 AND @IncludeThirdParty = 1))
AND (Calls.CallTypeID = @CallTypeID OR @CallTypeID IS NULL)

DROP TABLE #DefaultItemPrices
DROP TABLE #ContractorEngineers
DROP TABLE #CallFaultTypes

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetCallSLAReport] TO PUBLIC
    AS [dbo];

