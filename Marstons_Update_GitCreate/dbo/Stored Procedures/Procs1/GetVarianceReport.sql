CREATE PROCEDURE [dbo].[GetVarianceReport]
(
	@From	DATETIME = NULL,
	@To		DATETIME = NULL
)
AS

SET NOCOUNT ON
SET DATEFIRST 1

IF @To IS NULL
BEGIN
	SELECT @To = CAST(PropertyValue AS DATETIME)
	FROM Configuration
	WHERE PropertyName = 'AuditDate'
	
	SET @From = DATEADD(week, -8, @To)
	
END

DECLARE @PrimaryProducts TABLE(ProductID INT NOT NULL, PrimaryProductID INT NOT NULL)
INSERT INTO @PrimaryProducts
(ProductID, PrimaryProductID)
SELECT ProductID, ProductGroupPrimaries.PrimaryProductID
FROM ProductGroupProducts
JOIN ProductGroups ON ProductGroups.ID = ProductGroupProducts.ProductGroupID
JOIN (
	SELECT ProductGroupID, ProductID AS PrimaryProductID
	FROM ProductGroupProducts
	JOIN ProductGroups ON ProductGroups.ID = ProductGroupProducts.ProductGroupID
	WHERE TypeID = 1 AND IsPrimary = 1
) AS ProductGroupPrimaries ON ProductGroupPrimaries.ProductGroupID = ProductGroups.ID
WHERE TypeID = 1 AND IsPrimary = 0

--Merge system groups
DECLARE @PrimaryEDIS TABLE(PrimaryEDISID INT NOT NULL, EDISID INT NOT NULL)
INSERT INTO @PrimaryEDIS
SELECT MAX(PrimaryEDISID) AS PrimaryEDISID, SiteGroupSites.EDISID
FROM(
	SELECT SiteGroupID, SiteGroupSites.EDISID AS PrimaryEDISID
	FROM SiteGroupSites 
	WHERE SiteGroupID IN (SELECT ID FROM SiteGroups WHERE TypeID = 1)
	AND IsPrimary = 1
	GROUP BY SiteGroupID, SiteGroupSites.EDISID
) AS PrimarySites
JOIN SiteGroupSites ON SiteGroupSites.SiteGroupID = PrimarySites.SiteGroupID
LEFT JOIN PumpSetup ON PumpSetup.EDISID = SiteGroupSites.EDISID
GROUP BY SiteGroupSites.EDISID
ORDER BY PrimaryEDISID

SELECT	Sites.SiteID,
		COALESCE(SiteDailyDeliveries.ProductID, SiteDailyDispense.ProductID) AS VianetProductID,
		Products.[Description] AS VianetProductDescription,
		COALESCE(SiteDailyDeliveries.[Date], SiteDailyDispense.[Date]) AS [Date],
		ISNULL(SUM(SiteDailyDeliveries.Delivered), 0) AS Delivered,
		ISNULL(SUM(SiteDailyDispense.Dispensed), 0) AS Dispensed,
		ISNULL(SUM(SiteDailyDeliveries.Delivered), 0) - ISNULL(SUM(SiteDailyDispense.Dispensed), 0) AS Variance
FROM
(
	SELECT  COALESCE(PrimarySites.PrimaryEDISID, MasterDates.EDISID) AS EDISID,
			MasterDates.[Date],
			COALESCE(PrimaryProducts.PrimaryProductID, Delivery.Product) AS ProductID,
			SUM(Delivery.Quantity + 0.0) * 8.0 AS Delivered
	FROM MasterDates
	JOIN Sites ON Sites.EDISID = MasterDates.EDISID 
			   AND  (MasterDates.Date BETWEEN @From AND @To)
	JOIN Delivery ON Delivery.DeliveryID = MasterDates.ID
	LEFT JOIN Products ON Products.[ID] = Delivery.Product
	LEFT JOIN @PrimaryProducts AS PrimaryProducts ON PrimaryProducts.ProductID = Products.ID
	LEFT JOIN @PrimaryEDIS AS PrimarySites ON MasterDates.EDISID = PrimarySites.EDISID												  
	GROUP BY COALESCE(PrimarySites.PrimaryEDISID, MasterDates.EDISID),
			MasterDates.Date,
			COALESCE(PrimaryProducts.PrimaryProductID, Delivery.Product)
) AS SiteDailyDeliveries
FULL OUTER JOIN
(
SELECT  COALESCE(PrimarySites.PrimaryEDISID, MasterDates.EDISID) AS EDISID,
		MasterDates.Date,
		COALESCE(PrimaryProducts.PrimaryProductID, DLData.Product) AS ProductID,
		SUM(DLData.Quantity) AS Dispensed
FROM MasterDates
JOIN Sites ON Sites.EDISID = MasterDates.EDISID  
		   AND ( MasterDates.Date BETWEEN @From AND @To )
JOIN DLData ON DLData.DownloadID = MasterDates.ID
LEFT JOIN Products ON Products.[ID] = DLData.Product
LEFT JOIN @PrimaryProducts AS PrimaryProducts ON PrimaryProducts.ProductID = Products.ID
LEFT JOIN @PrimaryEDIS AS PrimarySites ON MasterDates.EDISID = PrimarySites.EDISID									   
GROUP BY COALESCE(PrimarySites.PrimaryEDISID, MasterDates.EDISID),
		MasterDates.Date,
		COALESCE(PrimaryProducts.PrimaryProductID, DLData.Product)
) AS SiteDailyDispense ON SiteDailyDispense.EDISID = SiteDailyDeliveries.EDISID AND
						  SiteDailyDispense.ProductID = SiteDailyDeliveries.ProductID AND
						  SiteDailyDispense.[Date] = SiteDailyDeliveries.[Date]
JOIN Sites ON Sites.EDISID = COALESCE(SiteDailyDeliveries.EDISID, SiteDailyDispense.EDISID)
JOIN Products ON Products.ID = COALESCE(SiteDailyDeliveries.ProductID, SiteDailyDispense.ProductID)
GROUP BY Sites.SiteID,
		 COALESCE(SiteDailyDeliveries.ProductID, SiteDailyDispense.ProductID),
		 Products.[Description],
		 COALESCE(SiteDailyDeliveries.[Date], SiteDailyDispense.[Date])
ORDER BY COALESCE(SiteDailyDeliveries.[Date], SiteDailyDispense.[Date]),
		 Sites.SiteID,
		 Products.[Description]

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetVarianceReport] TO PUBLIC
    AS [dbo];

