CREATE PROCEDURE dbo.GetDisposedSites
AS

SELECT COALESCE(Sites.EDISID, DisposedNotificationDate.EDISID, DisposedStatus.EDISID, DisposedFromDate.EDISID, DisposedToDatabaseID.EDISID) AS EDISID,
       ISNULL(DisposedNotificationDate.Value, 0) AS NotificationDate, 
       ISNULL(DisposedStatus.Value, 'Unknown') AS Status,
       ISNULL(DisposedFromDate.Value, 0) AS DisposedFromDate,
       ISNULL(DisposedToDatabaseID.Value, 0) AS DisposedToDatabaseID,
       ISNULL(DisposedCustomerAnnualPrice.Value, 0) AS DisposedCustomerAnnualPrice,
       ISNULL(DisposedTargetCustomerAnnualPrice.Value, 0) AS DisposedTargetCustomerAnnualPrice,
       ISNULL(UpliftCalls.CallID, 0) AS UpliftCall
FROM Sites
JOIN (
	SELECT EDISID, Value
	FROM SiteProperties
	JOIN Properties ON Properties.[ID] = SiteProperties.PropertyID
	WHERE Properties.[Name] = 'Disposed Notification Date'
) AS DisposedNotificationDate ON DisposedNotificationDate.EDISID = Sites.EDISID
FULL JOIN (
	SELECT EDISID, Value
	FROM SiteProperties
	JOIN Properties ON Properties.[ID] = SiteProperties.PropertyID
	WHERE Properties.[Name] = 'Disposed Status'
) AS DisposedStatus ON DisposedStatus.EDISID = Sites.EDISID
FULL JOIN (
	SELECT EDISID, Value
	FROM SiteProperties
	JOIN Properties ON Properties.[ID] = SiteProperties.PropertyID
	WHERE Properties.[Name] = 'Disposed To Date'
) AS DisposedFromDate ON DisposedFromDate.EDISID = Sites.EDISID
FULL JOIN (
	SELECT EDISID, Value
	FROM SiteProperties
	JOIN Properties ON Properties.[ID] = SiteProperties.PropertyID
	WHERE Properties.[Name] = 'Disposed To Database ID'
) AS DisposedToDatabaseID ON DisposedToDatabaseID.EDISID = Sites.EDISID
FULL JOIN (
	SELECT EDISID, Value
	FROM SiteProperties
	JOIN Properties ON Properties.[ID] = SiteProperties.PropertyID
	WHERE Properties.[Name] = 'Disposed Customer Annual Price'
) AS DisposedCustomerAnnualPrice ON DisposedCustomerAnnualPrice.EDISID = Sites.EDISID
FULL JOIN (
	SELECT EDISID, Value
	FROM SiteProperties
	JOIN Properties ON Properties.[ID] = SiteProperties.PropertyID
	WHERE Properties.[Name] = 'Disposed Target Customer Annual Price'
) AS DisposedTargetCustomerAnnualPrice ON DisposedTargetCustomerAnnualPrice.EDISID = Sites.EDISID
LEFT JOIN (
	SELECT TOP 1 Calls.EDISID, Calls.[ID] AS CallID --, COUNT(Calls.ID) AS UpliftCount
	FROM Calls
	JOIN InvoiceItems ON InvoiceItems.CallID = Calls.[ID]
	JOIN SiteProperties ON SiteProperties.EDISID = Calls.EDISID
	JOIN Properties ON Properties.[ID] = SiteProperties.PropertyID
	WHERE Properties.[Name] = 'Disposed Notification Date'
	AND InvoiceItems.ItemID = 110
	--AND Calls.RaisedOn >= CAST(SiteProperties.Value AS DATETIME)
	GROUP BY Calls.EDISID, Calls.[ID], Calls.RaisedOn
	ORDER BY Calls.RaisedOn DESC
) AS UpliftCalls ON UpliftCalls.EDISID = Sites.EDISID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetDisposedSites] TO PUBLIC
    AS [dbo];

