CREATE PROCEDURE [dbo].[GetWebSiteYieldTrackerSummary]
(
	@EDISID			INTEGER,
	@From			DATETIME,
	@To				DATETIME,
	@IncludeCasks	BIT = 1,
	@IncludeKegs	BIT = 1,
	@IncludeMetric	BIT = 0
)

AS

SET NOCOUNT ON

SET DATEFIRST 1

DECLARE @Sites TABLE (EDISID INT NOT NULL, PrimaryEDISID INT NOT NULL, SiteOnline DATETIME NOT NULL)
DECLARE @AllSitePumps TABLE (EDISID INT NOT NULL, PumpID INT NOT NULL, LocationID INT NOT NULL, ProductID INT NOT NULL)
DECLARE @SiteUsers TABLE (EDISID INT NOT NULL, RM INT NOT NULL, BDM INT NOT NULL)
DECLARE @BeerDispensed TABLE (EDISID INT NOT NULL, ProductID INT NOT NULL, ActualQuantity FLOAT NOT NULL, RoundedQuantity FLOAT NOT NULL)
DECLARE @BeerSold TABLE (EDISID INT NOT NULL, ProductID INT NOT NULL, Quantity FLOAT NOT NULL)
DECLARE @PrimaryProducts TABLE(ProductID INT NOT NULL, PrimaryProductID INT NOT NULL)


INSERT INTO @Sites
(EDISID, PrimaryEDISID, SiteOnline)
SELECT	SGS.EDISID AS [EDISID], 
		SGS2.EDISID AS [PrimaryEDISID],
		Sites.SiteOnline AS [SiteOnline]
FROM SiteGroupSites AS SGS
JOIN (SELECT SiteGroups.ID AS ID, SiteGroupSites.EDISID AS EDISID
	  FROM SiteGroups
	  JOIN SiteGroupSites
	    ON SiteGroupSites.SiteGroupID = SiteGroups.ID
	  WHERE SiteGroupSites.EDISID = @EDISID
	    AND SiteGroups.TypeID = 1) AS SGS2
  ON SGS2.ID = SGS.SiteGroupID
JOIN SiteGroups 
  ON SiteGroups.ID = SGS.SiteGroupID
JOIN Sites
  ON Sites.EDISID = SGS.EDISID
WHERE SiteGroups.TypeID = 1
UNION
SELECT	Sites.EDISID AS [EDISID],
		Sites.EDISID AS [PrimaryEDISID],
		Sites.SiteOnline AS [SiteOnline]
FROM Sites
WHERE Sites.EDISID = @EDISID
  AND Sites.EDISID NOT IN 
	(SELECT EDISID 
	 FROM SiteGroupSites
	 JOIN SiteGroups 
	   ON SiteGroups.ID = SiteGroupSites.SiteGroupID
	 WHERE SiteGroupSites.EDISID = @EDISID
	   AND SiteGroups.TypeID = 1)

-- Including multiple cellars from a Site causes issues atm (should be fixed properly later if this breaks it).
DELETE FROM @Sites 
WHERE EDISID <> PrimaryEDISID

-- Work out BDM and RM for each site (0 means no user)
INSERT INTO @SiteUsers
(EDISID, RM, BDM)
SELECT  UserSites.EDISID,
	MAX(CASE WHEN UserType = 1 THEN UserID ELSE 0 END) AS RM,
	MAX(CASE WHEN UserType = 2 THEN UserID ELSE 0 END) AS BDM
FROM UserSites
JOIN Users ON Users.ID = UserSites.UserID
JOIN @Sites AS RelevantSites ON UserSites.EDISID = RelevantSites.EDISID
WHERE UserType IN (1,2)
GROUP BY UserSites.EDISID

-- Unroll ProductGroups so we can work out how to transform ProductIDs to their primaries
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


INSERT INTO @BeerDispensed
(EDISID, ProductID, ActualQuantity, RoundedQuantity)
SELECT PrimarySites.PrimaryEDISID, ISNULL(PrimaryProducts.PrimaryProductID, Actions.Product), Actions.Pints, Actions.Drinks FROM
	(SELECT  DispenseActions.EDISID,
			DispenseActions.Product,
			TradingDay,
			SUM(Pints) AS Pints,
			SUM(EstimatedDrinks) AS Drinks
	FROM DispenseActions
	JOIN Products ON Products.ID = DispenseActions.Product
	WHERE TradingDay BETWEEN @From AND @To
	AND EDISID IN (SELECT EDISID FROM @Sites)
	AND (Products.IsCask = 0 OR @IncludeCasks = 1) 
	AND (Products.IsCask = 1 OR @IncludeKegs = 1) 
	AND (Products.IsMetric = 0 OR @IncludeMetric = 1)
	AND DispenseActions.LiquidType IN (2)
	GROUP BY DispenseActions.EDISID, DispenseActions.TradingDay, DispenseActions.Product) 
AS Actions
LEFT OUTER JOIN @PrimaryProducts AS PrimaryProducts ON PrimaryProducts.ProductID = Actions.Product
JOIN @Sites AS PrimarySites ON PrimarySites.EDISID = Actions.EDISID AND Actions.TradingDay >= SiteOnline 

-- All beer sold
INSERT INTO @BeerSold
(EDISID, ProductID, Quantity)
SELECT RelevantSites.PrimaryEDISID, ISNULL(PrimaryProducts.PrimaryProductID, Sold.ProductID), SUM(Sold.Quantity) FROM
		(SELECT EDISID, ProductID, Quantity, TradingDate
		FROM	
			(SELECT	Sales.EDISID,
					Sales.ProductID,
					SUM(Quantity) AS Quantity,
					TradingDate
			FROM Sales
			WHERE Sales.[TradingDate] BETWEEN @From AND DATEADD(Day, 1, @To)
			AND Sales.EDISID IN (SELECT EDISID FROM @Sites)
			GROUP BY EDISID, ProductID, TradingDate)
		AS EPOS
		JOIN Products 
		  ON Products.ID = EPOS.ProductID
		AND (Products.IsCask = 0 OR @IncludeCasks = 1) 
		AND (Products.IsCask = 1 OR @IncludeKegs = 1) 
		AND (Products.IsMetric = 0 OR @IncludeMetric = 1))
AS Sold
LEFT OUTER JOIN @PrimaryProducts AS PrimaryProducts ON PrimaryProducts.ProductID = Sold.ProductID
JOIN @Sites AS RelevantSites ON RelevantSites.EDISID = Sold.EDISID AND Sold.[TradingDate] >= RelevantSites.SiteOnline
GROUP BY RelevantSites.PrimaryEDISID, ISNULL(PrimaryProducts.PrimaryProductID, Sold.ProductID)



SELECT	ConfigCompany.PropertyValue AS Company,
		Owners.Name AS SubCompany,
		GroupedSites.PrimaryEDISID AS EDISID,
		Sites.SiteID AS SiteID, 
		Sites.Name AS Name,
		CAST(ISNULL(PouringBaseRP.ParameterValue, ConfigPouringBase.PropertyValue) AS INT)
			AS PouringYieldBasePercent,
		CAST((NULLIF(SUM(ISNULL(DispensedDrinks.RoundedQuantity,0)),0) / NULLIF(SUM(ISNULL(DispensedDrinks.ActualQuantity,0)),0) * 100) AS INT)
			AS PouringYieldActualPercent,
		CAST((NULLIF(SUM(ISNULL(DispensedDrinks.RoundedQuantity,0)),0) / NULLIF(SUM(ISNULL(DispensedDrinks.ActualQuantity,0)),0) * 100) AS INT) - CAST(ISNULL(PouringBaseRP.ParameterValue, ConfigPouringBase.PropertyValue) AS INT)
			AS PouringYieldDifference, 
		ISNULL(PouringTargetRP.ParameterValue, ConfigPouringTarget.PropertyValue) 
			AS PouringYieldTargetPercent,
		(NULLIF(SUM(ISNULL(DispensedDrinks.ActualQuantity,0)),0) * ((NULLIF(SUM(DispensedDrinks.RoundedQuantity),0) / NULLIF(SUM(DispensedDrinks.ActualQuantity),0) * 100) - CAST(ISNULL(PouringBaseRP.ParameterValue, ConfigPouringBase.PropertyValue) AS INT)) / 100) --* @PouringPint
			AS PouringYieldActualGain,
		(NULLIF(SUM(ISNULL(DispensedDrinks.ActualQuantity,0)),0) * (ISNULL(PouringTargetRP.ParameterValue, ConfigPouringTarget.PropertyValue) - CAST(ISNULL(PouringBaseRP.ParameterValue, ConfigPouringBase.PropertyValue) AS INT)) / 100) - (NULLIF(SUM(ISNULL(DispensedDrinks.ActualQuantity,0)),0) * ((NULLIF(SUM(DispensedDrinks.RoundedQuantity),0) / NULLIF(SUM(DispensedDrinks.ActualQuantity),0) * 100) - CAST(ISNULL(PouringBaseRP.ParameterValue, ConfigPouringBase.PropertyValue) AS INT)) / 100) --* @PouringPint
			AS PouringYieldPotentialGain,
		CAST(ISNULL(TillBaseRP.ParameterValue, ConfigTillBase.PropertyValue) AS INT)
			AS TillYieldBasePercent,
		CAST(ISNULL(CAST((NULLIF(SUM(ISNULL(DispensedDrinks.RoundedQuantity,0)),0) / NULLIF(SUM(ISNULL(SoldDrinks.Quantity,0)),0) * 1000) AS INT), 0) AS INT)
			AS TillYieldActualPercent,
		ISNULL(CAST((NULLIF(SUM(ISNULL(DispensedDrinks.RoundedQuantity,0)),0) / NULLIF(SUM(ISNULL(SoldDrinks.Quantity,0)),0) * 1000) AS INT), 0) - CAST(ISNULL(TillBaseRP.ParameterValue, ConfigTillBase.PropertyValue) AS INT)
			AS TillYieldDifference, --TillYieldActualPercent - TillYieldBasePercent
		ISNULL(TillTargetRP.ParameterValue, ConfigTillTarget.PropertyValue) 
			AS TillYieldTargetPercent,
		(((SUM(ISNULL(SoldDrinks.Quantity,0)) * CAST(ISNULL(CAST((NULLIF(SUM(ISNULL(DispensedDrinks.RoundedQuantity,0)),0) / NULLIF(SUM(ISNULL(SoldDrinks.Quantity,0)),0) * 1000) AS INT), 0) AS INT)) - CAST(ISNULL(TillBaseRP.ParameterValue, ConfigTillBase.PropertyValue) AS INT)) / 100)
			AS TillYieldActualGain,
		(((SUM(ISNULL(SoldDrinks.Quantity,0)) * CAST(ISNULL(TillTargetRP.ParameterValue, ConfigTillTarget.PropertyValue) AS INT)) - CAST(ISNULL(TillBaseRP.ParameterValue, ConfigTillBase.PropertyValue) AS INT)) / 100) - (((SUM(ISNULL(SoldDrinks.Quantity,0)) * CAST(ISNULL(CAST((NULLIF(SUM(ISNULL(DispensedDrinks.RoundedQuantity,0)),0) / NULLIF(SUM(ISNULL(SoldDrinks.Quantity,0)),0) * 1000) AS INT), 0) AS INT)) - CAST(ISNULL(TillBaseRP.ParameterValue, ConfigTillBase.PropertyValue) AS INT)) / 100)
			AS TillYieldPotentialGain
FROM Sites
JOIN (SELECT DISTINCT PrimaryEDISID FROM @Sites ) AS GroupedSites
  ON GroupedSites.PrimaryEDISID = Sites.EDISID
JOIN Owners
  ON Owners.ID = Sites.OwnerID
JOIN Configuration AS ConfigCompany 
  ON ConfigCompany.PropertyName = 'Company Name'
JOIN Configuration AS ConfigPouringBase
  ON ConfigPouringBase.PropertyName = 'Pouring Yield Base Percentage Default'
JOIN Configuration AS ConfigTillBase
  ON ConfigTillBase.PropertyName = 'Till Yield Base Percentage Default'
JOIN Configuration AS ConfigPouringTarget
  ON ConfigPouringTarget.PropertyName = 'Pouring Yield Target Percentage Default'
JOIN Configuration AS ConfigTillTarget
  ON ConfigTillTarget.PropertyName = 'Till Yield Target Percentage Default'
LEFT JOIN @BeerDispensed AS DispensedDrinks
  ON DispensedDrinks.EDISID = GroupedSites.PrimaryEDISID
LEFT JOIN @BeerSold AS SoldDrinks
  ON SoldDrinks.EDISID = GroupedSites.PrimaryEDISID  
 AND SoldDrinks.ProductID = DispensedDrinks.ProductID
LEFT JOIN ReportParameters AS PouringBaseRP
  ON PouringBaseRP.EDISID = Sites.EDISID
 AND PouringBaseRP.ReportID = 1 AND PouringBaseRP.ParameterID = 1 --Pouring Yield Base
LEFT JOIN ReportParameters AS PouringTargetRP
  ON PouringTargetRP.EDISID = Sites.EDISID
 AND PouringTargetRP.ReportID = 1 AND PouringTargetRP.ParameterID = 2 --Pouring Yield Target
LEFT JOIN ReportParameters AS TillBaseRP
  ON TillBaseRP.EDISID = Sites.EDISID
 AND TillBaseRP.ReportID = 1 AND TillBaseRP.ParameterID = 3 --Till Yield Base
LEFT JOIN ReportParameters AS TillTargetRP
  ON TillTargetRP.EDISID = Sites.EDISID
 AND TillTargetRP.ReportID = 1 AND TillTargetRP.ParameterID = 4 --Till Yield Target
GROUP BY ConfigCompany.PropertyValue, 
		 Owners.Name, 
		 GroupedSites.PrimaryEDISID, 
		 Sites.SiteID, 
		 Sites.Name, 
		 PouringBaseRP.ParameterValue, 
		 ConfigPouringBase.PropertyValue, 
		 PouringTargetRP.ParameterValue, 
		 ConfigPouringTarget.PropertyValue, 
		 TillBaseRP.ParameterValue, 
		 ConfigTillBase.PropertyValue, 
		 TillTargetRP.ParameterValue, 
		 ConfigTillTarget.PropertyValue
ORDER BY Sites.SiteID
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetWebSiteYieldTrackerSummary] TO PUBLIC
    AS [dbo];

