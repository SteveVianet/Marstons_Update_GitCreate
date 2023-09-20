CREATE PROCEDURE GetUserSitesProductRedAlertReport
(
	@UserID 	INT,
	@From 	SMALLDATETIME,
	@To 		SMALLDATETIME
)

AS

DECLARE @InternalUserID	INT
DECLARE @InternalFrom 	SMALLDATETIME
DECLARE @InternalTo 	SMALLDATETIME
DECLARE @Dispensed	TABLE([ProductID] INT NOT NULL, Quantity FLOAT NOT NULL)
DECLARE @Delivered		TABLE([ProductID] INT NOT NULL, Quantity FLOAT NOT NULL)
DECLARE @Sold		TABLE([ProductID] INT NOT NULL, Quantity FLOAT NOT NULL)

SET @InternalUserID = @UserID
SET @InternalFrom = @From
SET @InternalTo = @To

DECLARE @AllSitesVisible	BIT

SET NOCOUNT ON

SELECT @AllSitesVisible = AllSitesVisible
FROM dbo.UserTypes
JOIN dbo.Users ON Users.UserType = UserTypes.[ID]
WHERE dbo.Users.[ID] = @InternalUserID

IF @AllSitesVisible = 1
BEGIN
	INSERT INTO @Dispensed
	SELECT DLData.Product AS ProductID, SUM(DLData.Quantity) AS Quantity
	FROM dbo.MasterDates
	JOIN dbo.DLData ON MasterDates.[ID] = DLData.DownloadID
	JOIN Sites ON Sites.EDISID = MasterDates.EDISID
	WHERE MasterDates.[Date] BETWEEN @InternalFrom AND @InternalTo
	AND MasterDates.[Date] >= Sites.SiteOnline
	GROUP BY DLData.Product

	INSERT INTO @Delivered
	SELECT Delivery.Product AS ProductID, SUM(Delivery.Quantity) AS Quantity
	FROM dbo.MasterDates
	JOIN dbo.Delivery ON MasterDates.[ID] = Delivery.DeliveryID
	JOIN Sites ON Sites.EDISID = MasterDates.EDISID
	WHERE MasterDates.[Date] BETWEEN @InternalFrom AND @InternalTo
	AND MasterDates.[Date] >= Sites.SiteOnline
	GROUP BY Delivery.Product
	
	INSERT INTO @Sold
	SELECT Sales.ProductID AS ProductID, SUM(Sales.Quantity) AS Quantity
	FROM MasterDates
	JOIN Sales ON MasterDates.[ID] = Sales.MasterDateID
	JOIN Sites ON Sites.EDISID = MasterDates.EDISID
	WHERE  MasterDates.[Date] BETWEEN @InternalFrom AND @InternalTo
	AND MasterDates.[Date] >= Sites.SiteOnline
	GROUP BY Sales.ProductID

	SELECT COALESCE(Dispensed.ProductID, Delivered.ProductID, Sold.ProductID) AS [ProductID],
		ISNULL(Dispensed.Quantity, 0) AS Dispensed,
		ISNULL(Delivered.Quantity, 0) AS Delivered,
		ISNULL(Sold.Quantity, 0) AS Sold
	FROM @Dispensed AS Dispensed
	FULL JOIN @Delivered AS Delivered ON Dispensed.[ProductID] = Delivered.[ProductID]
	FULL JOIN @Sold AS Sold ON Dispensed.[ProductID] = Sold.[ProductID]
	JOIN Products ON Products.[ID] = COALESCE(Dispensed.ProductID, Delivered.ProductID, Sold.ProductID)
	WHERE Products.IsWater = 0
	ORDER BY ProductID

END
ELSE
BEGIN
	INSERT INTO @Dispensed
	SELECT DLData.Product AS ProductID, SUM(DLData.Quantity) AS Quantity
	FROM dbo.MasterDates
	JOIN dbo.DLData ON MasterDates.[ID] = DLData.DownloadID
	JOIN Sites ON Sites.EDISID = MasterDates.EDISID
	JOIN UserSites ON MasterDates.EDISID = UserSites.EDISID
	WHERE MasterDates.[Date] BETWEEN @InternalFrom AND @InternalTo
	AND MasterDates.[Date] >= Sites.SiteOnline
	AND UserSites.UserID = @UserID
	GROUP BY DLData.Product

	INSERT INTO @Delivered
	SELECT Delivery.Product AS ProductID, SUM(Delivery.Quantity) AS Quantity
	FROM dbo.MasterDates
	JOIN dbo.Delivery ON MasterDates.[ID] = Delivery.DeliveryID
	JOIN Sites ON Sites.EDISID = MasterDates.EDISID
	JOIN UserSites ON MasterDates.EDISID = UserSites.EDISID
	WHERE MasterDates.[Date] BETWEEN @InternalFrom AND @InternalTo
	AND MasterDates.[Date] >= Sites.SiteOnline
	AND UserSites.UserID = @UserID
	GROUP BY Delivery.Product

	INSERT INTO @Sold
	SELECT Sales.ProductID AS ProductID, SUM(Sales.Quantity) AS Quantity
	FROM dbo.MasterDates
	JOIN dbo.Sales ON MasterDates.[ID] = Sales.MasterDateID
	JOIN Sites ON Sites.EDISID = MasterDates.EDISID
	JOIN UserSites ON MasterDates.EDISID = UserSites.EDISID
	WHERE MasterDates.[Date] BETWEEN @InternalFrom AND @InternalTo
	AND MasterDates.[Date] >= Sites.SiteOnline
	AND UserSites.UserID = @UserID
	GROUP BY Sales.ProductID

	SELECT COALESCE(Dispensed.ProductID, Delivered.ProductID, Sold.ProductID) AS [ProductID],
		ISNULL(Dispensed.Quantity, 0) AS Dispensed,
		ISNULL(Delivered.Quantity, 0) AS Delivered,
		ISNULL(Sold.Quantity, 0) AS Sold
	FROM @Dispensed AS Dispensed
	FULL JOIN @Delivered AS Delivered ON Dispensed.[ProductID] = Delivered.[ProductID]
	FULL JOIN @Sold AS Sold ON Dispensed.[ProductID] = Sold.[ProductID]
	JOIN Products ON Products.[ID] = COALESCE(Dispensed.ProductID, Delivered.ProductID, Sold.ProductID)
	WHERE Products.IsWater = 0
	ORDER BY ProductID

END


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetUserSitesProductRedAlertReport] TO PUBLIC
    AS [dbo];

