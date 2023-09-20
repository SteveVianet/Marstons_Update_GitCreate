CREATE PROCEDURE [dbo].[GetWebUserSitesFontUtilisation]
(
	@UserID			INTEGER,
	@From			DATETIME,
	@To				DATETIME,
	@PintThreshold	INTEGER
)

AS

SET NOCOUNT ON

SET DATEFIRST 1

DECLARE @Sites TABLE(EDISID INT NOT NULL, PrimaryEDISID INT NOT NULL, SiteOnline DATETIME NOT NULL)
DECLARE @Results TABLE(Counter INT IDENTITY(1,1) PRIMARY KEY, Company VARCHAR(255) NOT NULL, SubCompany VARCHAR(255) NOT NULL, EDISID INT NOT NULL, SiteID VARCHAR(15) NOT NULL, Name VARCHAR(60) NOT NULL, Taps INT NOT NULL, TargetTaps INT NOT NULL, TapsNotDispensing INT NOT NULL, TapsBelowThreshold INT NOT NULL)

DECLARE @AllSitePumps TABLE (EDISID INT NOT NULL, PumpID INT NOT NULL, LocationID INT NOT NULL, ProductID INT NOT NULL)

DECLARE @Anonymise			BIT

DECLARE @TapCount TABLE (PrimaryEDISID INT NOT NULL, [Count] INT NOT NULL)
DECLARE @UserHasAllSites	BIT

DECLARE @PrimaryProducts TABLE(ProductID INT NOT NULL, PrimaryProductID INT NOT NULL)

DECLARE @WeeklyPumpDispense TABLE (EDISID INT NOT NULL, TradingDate DATETIME NOT NULL, PumpID INT NOT NULL, Quantity FLOAT NOT NULL)
DECLARE @PumpDispenseActivity TABLE (EDISID INT NOT NULL, PumpID INT NOT NULL, NoActivity BIT NOT NULL, LowActivity BIT NOT NULL)

SELECT @UserHasAllSites = AllSitesVisible, @Anonymise = dbo.Users.Anonymise
FROM dbo.UserTypes
JOIN dbo.Users ON Users.UserType = UserTypes.[ID]
WHERE dbo.Users.[ID] = @UserID

INSERT INTO @Sites
(EDISID, PrimaryEDISID, SiteOnline)
SELECT	SGS.EDISID AS [EDISID], 
		SGS2.EDISID AS [PrimaryEDISID],
		Sites.SiteOnline AS [SiteOnline]
FROM SiteGroupSites AS SGS
JOIN (SELECT SiteGroupID, EDISID 
	  FROM SiteGroupSites 
	  JOIN SiteGroups 
	    ON SiteGroups.ID = SiteGroupSites.SiteGroupID
	  WHERE IsPrimary = 1 
	    AND TypeID = 1) AS SGS2 
  ON SGS2.SiteGroupID = SGS.SiteGroupID
JOIN SiteGroups 
  ON SiteGroups.ID = SGS.SiteGroupID
JOIN UserSites 
  ON UserSites.EDISID = SGS2.EDISID
 AND @UserHasAllSites = 0
JOIN Sites 
  ON Sites.EDISID = UserSites.EDISID
WHERE SiteGroups.TypeID = 1
  AND UserSites.UserID = @UserID
  AND Sites.Quality = 1
UNION
SELECT	UserSites.EDISID AS [EDISID],
		UserSites.EDISID AS [PrimaryEDISID],
		Sites.SiteOnline AS [SiteOnline]
FROM UserSites
JOIN Sites 
  ON Sites.EDISID = UserSites.EDISID
WHERE UserSites.UserID = @UserID
  AND UserSites.EDISID NOT IN (
					SELECT EDISID 
					FROM SiteGroupSites 
					JOIN SiteGroups ON SiteGroups.ID = SiteGroupSites.SiteGroupID
					WHERE SiteGroups.TypeID = 1)
  AND Sites.Quality = 1	

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


INSERT INTO @WeeklyPumpDispense
(EDISID, TradingDate, PumpID, Quantity)
SELECT EDISID, DATEADD(day, -DATEPART(dw, TradingDate) +1 , TradingDate), PumpID, SUM(Quantity)
FROM (SELECT  DispenseActions.EDISID,
		TradingDay AS TradingDate,
		Pump AS PumpID,
		SUM(Pints) AS Quantity
	FROM DispenseActions
	JOIN Products ON Products.[ID] = DispenseActions.Product
	LEFT OUTER JOIN @PrimaryProducts AS PrimaryProducts ON PrimaryProducts.ProductID = DispenseActions.Product
	WHERE TradingDay BETWEEN @From AND DATEADD(day, -DATEPART(dw, @To) +7 , @To)
	AND DispenseActions.EDISID IN (SELECT EDISID FROM @Sites)
	AND Products.IsMetric = 0
	AND DispenseActions.LiquidType IN (2, 3, 5)
	GROUP BY DispenseActions.EDISID, TradingDay, Pump)
AS TradingDispense
GROUP BY EDISID, DATEADD(day, -DATEPART(dw, TradingDate) +1 , TradingDate), PumpID
ORDER BY EDISID, DATEADD(day, -DATEPART(dw, TradingDate) +1 , TradingDate), PumpID




INSERT INTO @PumpDispenseActivity
(EDISID, PumpID, NoActivity, LowActivity)
SELECT  Pumps.EDISID,
		Pumps.Pump, 
		CASE WHEN SUM(WPD.Quantity) IS NULL
			 THEN 1
			 ELSE 0 END AS NoActivity,
		CASE WHEN SUM(WPD.Quantity) < @PintThreshold
			 THEN 1
			 ELSE 0 END AS LowActivity
FROM PumpSetup AS Pumps
JOIN @Sites AS Sites 
  ON Sites.EDISID = Pumps.EDISID
JOIN Products ON Products.ID = Pumps.ProductID
FULL OUTER JOIN @WeeklyPumpDispense AS WPD 
             ON WPD.PumpID = Pumps.Pump
            AND WPD.EDISID = Pumps.EDISID
WHERE (ValidFrom <= DATEADD(day, -DATEPART(dw, @To) +7 , @To))
AND (ISNULL(ValidTo, DATEADD(day, -DATEPART(dw, @To) +7 , @To)) >= @From)
AND (ISNULL(ValidTo, DATEADD(day, -DATEPART(dw, @To) +7 , @To)) >= Sites.SiteOnline)
--AND (Pumps.InUse = 1)
AND Products.IsMetric = 0
GROUP BY Pumps.EDISID, Pumps.Pump

/*
SELECT PumpSetup.* FROM PumpSetup
JOIN Products ON Products.ID = PumpSetup.ProductID
WHERE EDISID = 15
AND IsMetric = 0
--AND InUse = 1

EXEC GetHistoricalFont 15, NULL, '2010-01-25', '2010-01-31'

EXEC [GetSiteDispenseConditionsMinimumPumpDispense] 15, '2010-01-25', '2010-01-31', 20, 0
*/

INSERT INTO @TapCount
(PrimaryEDISID, [Count])
SELECT	Sites.PrimaryEDISID, 
		COUNT(DISTINCT(Pump))
FROM PumpSetup
JOIN @Sites AS Sites 
  ON Sites.EDISID = PumpSetup.EDISID
JOIN Products ON Products.ID = PumpSetup.ProductID
WHERE 
--(ValidFrom <= DATEADD(day, -DATEPART(dw, @From) +1 , @From)) AND 
(ISNULL(ValidTo, DATEADD(day, -DATEPART(dw, @To) +7 , @To)) >= @From)
AND (ISNULL(ValidTo, DATEADD(day, -DATEPART(dw, @To) +7 , @To)) >= Sites.SiteOnline)
--AND PumpSetup.InUse = 1
AND Products.IsMetric = 0
GROUP BY Sites.PrimaryEDISID

INSERT INTO @Results 
(Company, SubCompany, EDISID, SiteID, Name, Taps, TargetTaps, TapsNotDispensing, TapsBelowThreshold)
SELECT	Configuration.PropertyValue AS Company,
		Owners.Name AS SubCompany,
		GroupedSites.PrimaryEDISID AS EDISID,
		Sites.SiteID AS SiteID, 
		Sites.Name AS Name,
		TapCount.[Count] AS Taps,
		TapCount.[Count] - (SUM(CONVERT(INT,NoActivity)) + SUM(CONVERT(INT,LowActivity))) AS TargetTaps,
		SUM(CONVERT(INT,NoActivity)) AS TapsNotDispensing, 
		SUM(CONVERT(INT,LowActivity)) AS TapsBelowThreshold
FROM @PumpDispenseActivity AS PDA
JOIN @Sites AS GroupedSites
  ON GroupedSites.EDISID = PDA.EDISID
JOIN Sites
  ON Sites.EDISID = GroupedSites.PrimaryEDISID
JOIN Owners
  ON Owners.ID = Sites.OwnerID
JOIN Configuration 
  ON Configuration.PropertyName = 'Company Name'
JOIN @TapCount AS TapCount
  ON TapCount.PrimaryEDISID = GroupedSites.PrimaryEDISID
GROUP BY GroupedSites.PrimaryEDISID, Configuration.PropertyValue, Owners.Name, Sites.SiteID, Sites.Name, TapCount.[Count]

-- Bodge site details for demo purposes if we need to
UPDATE @Results
SET  Company = WebDemoSites.CompanyName,
	SubCompany = WebDemoSites.SubCompanyName,
	SiteID = 'pub' + CAST(Counter AS VARCHAR),
	[Name] = WebDemoSites.[SiteName]
FROM [SQL1\SQL1].ServiceLogger.dbo.WebDemoSites AS WebDemoSites
WHERE @Anonymise = 1 AND Counter = WebDemoSites.CounterID

-- If the anonymised site details list doesn't have enough entries, strip all untouched sites for privacy reasons
DELETE FROM @Results
WHERE SiteID NOT LIKE 'pub%'
  AND @Anonymise = 1

-- Return results
SELECT Company, SubCompany, EDISID, SiteID, Name, Taps, TargetTaps, TapsNotDispensing, TapsBelowThreshold
FROM @Results

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetWebUserSitesFontUtilisation] TO PUBLIC
    AS [dbo];

