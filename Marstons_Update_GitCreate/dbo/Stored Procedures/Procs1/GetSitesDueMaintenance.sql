CREATE PROCEDURE [dbo].[GetSitesDueMaintenance]
AS

SET NOCOUNT ON

DECLARE @Today DATETIME
SET @Today = GETDATE()

SELECT	CAST(DatabaseID.PropertyValue AS INTEGER) AS DatabaseID,
		CAST(Customer.PropertyValue AS VARCHAR) AS CustomerName,
		Sites.EDISID,
		Sites.SiteID,
		Sites.Name,
		Sites.PostCode,
		Contracts.ID AS ContractID,
		Contracts.[Description] AS ContractName,
		Contracts.MaintenancePeriodMax AS MaintenanceMonthSchedule,
		COALESCE(Sites.LastMaintenanceDate, Sites.LastInstallationDate, CAST('1899-12-30' AS DATETIME)) AS LastMaintenanceDate,
		DATEADD(MONTH, Contracts.MaintenancePeriodMax, COALESCE(LastMaintenanceDate, LastInstallationDate, CAST('1899-12-30' AS DATETIME))) AS MaintenanceDueDate,
		Sites.LastPATDate,
		CASE WHEN OpenMaintenanceCalls.EDISID IS NULL AND DATEDIFF(MONTH, COALESCE(LastMaintenanceDate, LastInstallationDate, CAST('1899-12-30' AS DATETIME)), @Today) >= Contracts.MaintenancePeriodMax THEN 1 ELSE 0 END AS DueMaintenance,
		dbo.GetCallReference(LastMaintenanceCall.LastMaintenanceCallID) AS LastMaintenanceCallReference,
		CASE WHEN CompletedMaintenanceBillingItems.CallID IS NOT NULL THEN 1 ELSE 0 END AS IsLastMaintenanceCallCompleted,
		Sites.LastElectricalCheckDate
FROM Sites
JOIN Configuration AS DatabaseID ON DatabaseID.PropertyName = 'Service Owner ID'
JOIN Configuration AS Customer ON Customer.PropertyName = 'Company Name'
JOIN SiteContracts ON SiteContracts.EDISID = Sites.EDISID
JOIN Contracts ON Contracts.ID = SiteContracts.ContractID
LEFT JOIN
(
	SELECT DISTINCT Calls.EDISID
	FROM Calls
	JOIN (	SELECT CallID, MAX(ID) AS LastStatusID
			FROM CallStatusHistory
			GROUP BY CallID  ) AS LastCallStatus ON LastCallStatus.CallID = Calls.ID
	JOIN CallStatusHistory ON CallStatusHistory.ID = LastCallStatus.LastStatusID
	JOIN CallReasons ON CallReasons.CallID = Calls.ID
	WHERE CallReasons.ReasonTypeID = 41 --Standard maintenance check
	AND CallStatusHistory.StatusID <> 4
) AS OpenMaintenanceCalls ON OpenMaintenanceCalls.EDISID = Sites.EDISID
LEFT JOIN
(
	SELECT EDISID, MAX(Calls.ID) AS LastMaintenanceCallID
	FROM Calls
	JOIN (	SELECT CallID, MAX(ID) AS LastStatusID
			FROM CallStatusHistory
			GROUP BY CallID  ) AS LastCallStatus ON LastCallStatus.CallID = Calls.ID
	JOIN CallStatusHistory ON CallStatusHistory.ID = LastCallStatus.LastStatusID
	JOIN CallReasons ON CallReasons.CallID = Calls.ID
	WHERE CallReasons.ReasonTypeID = 41 --Standard maintenance check
	AND CallStatusHistory.StatusID = 4
	GROUP BY EDISID
) AS LastMaintenanceCall ON LastMaintenanceCall.EDISID = Sites.EDISID
LEFT JOIN CallBillingItems AS CompletedMaintenanceBillingItems ON CompletedMaintenanceBillingItems.CallID = LastMaintenanceCall.LastMaintenanceCallID AND CompletedMaintenanceBillingItems.BillingItemID = 107
WHERE Hidden = 0
AND Contracts.MaintenancePeriodMax <= 5000

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSitesDueMaintenance] TO PUBLIC
    AS [dbo];

