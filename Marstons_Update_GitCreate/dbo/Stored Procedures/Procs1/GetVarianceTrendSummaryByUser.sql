CREATE PROCEDURE [dbo].[GetVarianceTrendSummaryByUser] (
	@EDISID INT = NULL,
	@UserID INT = NULL,
	@From DATE,
	@To DATE, 
	@IncludeClosedSites BIT
	)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.

	--Get Multi-Cellar Sites
	SET NOCOUNT ON;

	DECLARE @Sites TABLE (
    EDISID INT,
	PrimaryEDISID INT,
    PrimarySiteID VARCHAR(50),
    PrimarySiteName VARCHAR(50),
    Town  VARCHAR(50),
	BDM VARCHAR(50)
	)
 
	INSERT INTO @Sites 
	SELECT DISTINCT us.EDISID, s.EDISID, s.SiteID, s.Name,
        CASE
            WHEN s.Address3 = '' AND s.Address2 = '' THEN s.Address1
            WHEN s.Address3 = '' THEN s.Address2
            ELSE s.Address3
        END AS Town,
		BDM.UserName
    FROM UserSites AS us
    LEFT JOIN (
		SELECT SiteGroupID,EDISID
		FROM SiteGroupSites AS s    
		LEFT JOIN SiteGroups AS sg
			ON s.SiteGroupID = sg.ID
		WHERE sg.TypeID = 1
    ) AS sgs
		ON sgs.EDISID = us.EDISID
	LEFT JOIN SiteGroupSites AS sgs2
		ON sgs2.SiteGroupID = sgs.SiteGroupID AND sgs2.IsPrimary = 1
    JOIN Sites AS s
		ON s.EDISID = COALESCE(sgs2.EDISID, us.EDISID)
	-- Get BDM for Site
	JOIN ( SELECT us.EDISID, u.UserName
		FROM UserSites AS us
		JOIN Users AS u
			ON u.ID = us.UserID
		WHERE u.UserType = 2	-- Get BDM's only
		) AS BDM
		ON BDM.EDISID = s.EDISID		
    WHERE (us.UserID = @UserID	OR @UserID IS NULL)
		AND (s.EDISID = @EDISID OR @EDISID IS NULL)
		AND (@IncludeClosedSites = 1 OR s.SiteClosed = 0)


	-- Get products by group and assign primary product
	CREATE TABLE #SiteProducts (
		EDISID INT,
		PrimaryEDISID INT, 
		PrimarySiteID VARCHAR(50),
		PrimarySiteName VARCHAR(50),
		Town VARCHAR(50),
		BDM VARCHAR (50),
		ProductID INT,
		GroupID INT,
		GroupName VARCHAR(50),
		IsCask BIT,
		IsMetric BIT,
		IsTied BIT
		)

	INSERT INTO #SiteProducts 
	SELECT DISTINCT s.EDISID,
		s.PrimaryEDISID, 
		s.PrimarySiteID, 
		s.PrimarySiteName, 
		s.Town, 
		s.BDM,
		ddp.Product,
		pgp2.ProductGroupID,
		COALESCE(pgp2.[Description], p.[Description]) As Name,
		p.IsCask, 
		p.IsMetric, 
		p.Tied AS IsTied
	FROM @Sites AS s
	JOIN MasterDates AS md
		ON md.EDISID = s.EDISID
	-- Get all downloaded and dispensed products per site
	JOIN (SELECT DownloadID, Product
			FROM DLData
			GROUP BY DownloadID, Product
			UNION
			SELECT DeliveryID, Product
			FROM Delivery
			GROUP BY DeliveryID, Product) AS ddp
		ON ddp.DownloadID = md.ID
	JOIN Products AS p
		ON p.ID = ddp.Product
	-- Get Type 2 Product Groups
	LEFT JOIN (
			SELECT * 
			FROM ProductGroupProducts AS pgp 
			JOIN ProductGroups AS pg
				ON pg.ID = pgp.ProductGroupID
			WHERE pg.TypeID = 1
			) AS pgp2
		ON pgp2.ProductID = p.ID
	-- Get Tied info per site
	LEFT JOIN SiteProductTies AS spt
		ON spt.EDISID = md.EDISID AND spt.ProductID = ddp.Product
	LEFT JOIN SiteProductCategoryTies AS spct
		ON md.EDISID = spct.EDISID AND p.CategoryID = spct.ProductCategoryID
	WHERE md.[Date] BETWEEN @From AND @To


	CREATE TABLE #Main  (
		EDISID INT,
		PrimaryEDISID INT, 
		PrimarySiteID INT,
		PrimarySiteName VARCHAR(50),
		Town VARCHAR(50),
		BDM VARCHAR(50),
		[Date] DATE,
		ProductID INT,
		GroupID INT,
		GroupName VARCHAR(50), 
		IsCask BIT, 
		IsMetric BIT,
		IsTied BIT,
		Dispensed FLOAT,
		Delivered FLOAT,
		BeforeDelivery BIT,
		Stock FLOAT
	)
	
	INSERT INTO #Main	
	SELECT 
		sp.EDISID,
		sp.PrimaryEDISID,
		sp.PrimarySiteID,
		sp.PrimarySiteName,
		sp.Town,
		sp.BDM,
		cal.[CalendarDate] AS [Date],
		sp.ProductID,
		COALESCE(sp.GroupID, sp.ProductID) AS GroupID,
		sp.GroupName,		
		sp.IsCask, 
		sp.IsMetric,
		sp.IsTied,
		dis.Quantity AS Dispensed,
		del.Quantity AS Delivered,
		stk.BeforeDelivery,
		stk.Quantity * 8 AS Stock
	FROM #SiteProducts AS sp
	-- Make sure every site and product has a date - ensures all columns show in SSRS
	CROSS JOIN (SELECT CalendarDate
				FROM Calendar
				WHERE CalendarDate BETWEEN @From AND @To) AS cal
	LEFT JOIN MasterDates AS md
		ON md.[Date] = cal.CalendarDate AND md.EDISID = sp.EDISID
	LEFT JOIN (SELECT dld.DownloadID, dld.Product, SUM(dld.Quantity) As Quantity
				FROM DLData AS dld
				GROUP BY dld.DownloadID, dld.Product
				) AS dis
		ON dis.DownloadID = md.ID AND dis.Product = sp.ProductID
	LEFT JOIN (SELECT d.DeliveryID, d.Product, SUM(d.Quantity) * 8 As Quantity -- Delivered stored as gallons - converting to pints
				FROM Delivery AS d
				GROUP BY d.DeliveryID, d.Product
				) AS del
		ON del.DeliveryID = md.ID AND del.Product = sp.ProductID
	LEFT JOIN Stock AS stk
		ON stk.MasterDateID = md.ID AND stk.ProductID = sp.ProductID

	
	----Get last StockDates
	;WITH StockDates
	AS
	(
		SELECT DISTINCT m.EDISID, m.ProductID, MAX(m.Date) OVER(PARTITION BY m.EDISID, m.ProductID) AS StockDate
		FROM #Main AS m
		LEFT JOIN (
			SELECT * 
			FROM ProductGroupProducts AS pgp 
			JOIN ProductGroups AS pg
				ON pg.ID = pgp.ProductGroupID
			WHERE pg.TypeID = 1
			) AS pgp2
		ON pgp2.ProductID = m.ProductID
		WHERE NOT m.BeforeDelivery IS NULL
		
	),
	MainWithStock
	AS
	(
		-- Anchor - List entries corresponding to latest stock date
		SELECT m.*,
			CASE m.BeforeDelivery
				WHEN 1 THEN (m.Stock + ISNULL(m.Delivered, 0) - ISNULL(m.Dispensed, 0)) 
				WHEN 0 THEN (m.Stock - ISNULL(m.Dispensed, 0))
			END AS RemainingStock, 
			CAST(NULL AS DATE) AS DayBefore			
		FROM #Main AS m
		LEFT JOIN StockDates AS sd
			ON sd.EDISID = m.EDISID AND sd.ProductID = m.ProductID			
		WHERE m.BeforeDelivery IS NOT NULL AND m.Date = sd.StockDate

		UNION ALL

		--Recursive Query here

		SELECT 
			m.*,
			(mws.RemainingStock - ISNULL(m.Dispensed, 0) + ISNULL(m.Delivered, 0)) AS RemainingStock,
			mws.Date
		FROM #Main AS m
		JOIN MainWithStock AS mws
			ON mws.EDISID = m.EDISID AND mws.[Date] = DATEADD(DAY, -1, m.[Date]) AND mws.ProductID = m.ProductID		
	)

	---- ## MAIN QUERY ##

	---- Get all rows prior to the stock check, or where there is no stock check for a product in this period 
	SELECT
		m.EDISID,
		m.PrimaryEDISID,
		m.PrimarySiteID,
		m.PrimarySiteName,
		m.Town,
		m.BDM,
		m.[Date],
		--m.ProductID,
		m.GroupID,
		m.GroupName,		
		m.IsCask, 
		m.IsMetric,
		m.IsTied,
		SUM(m.Dispensed) AS Dispensed,
		SUM(m.Delivered) AS Delivered,
		(ISNULL(SUM(m.Delivered), 0) - ISNULL(SUM(m.Dispensed), 0)) AS Variance,
		CAST(NULL AS FLOAT) AS RemainingStock
	FROM #Main AS m
	LEFT JOIN StockDates AS sd
		ON sd.ProductID = m.ProductID AND m.EDISID = sd.EDISID
		-- Select all rows before the last stock date, or all rows for any EDISID + product that doesn't have a stock date
	WHERE m.Date < sd.StockDate OR sd.StockDate IS NULL
	GROUP BY m.EDISID,
		m.PrimaryEDISID,
		m.PrimarySiteID,
		m.PrimarySiteID, m.PrimarySiteName, m.Town, m.BDM, m.[Date], m.ProductID, m.GroupID,
		m.GroupName,
		m.IsCask, 
		m.IsMetric,
		m.IsTied

	UNION ALL

	SELECT
		mws.EDISID,
		mws.PrimaryEDISID,
		mws.PrimarySiteID,
		mws.PrimarySiteName,
		mws.Town,
		mws.BDM,
		mws.[Date],
		--mws.ProductID,
		mws.GroupID,
		mws.GroupName,		
		mws.IsCask, 
		mws.IsMetric,
		mws.IsTied,		
		SUM(mws.Dispensed) AS Dispensed,
		SUM(mws.Delivered) AS Delivered,
		(ISNULL(SUM(mws.Delivered), 0) - ISNULL(SUM(mws.Dispensed), 0)) AS Variance,
		SUM(mws.RemainingStock) AS RemainingStock
	FROM MainWithStock AS mws 
	GROUP BY mws.EDISID,
		mws.PrimaryEDISID,
		mws.PrimarySiteID,
		mws.PrimarySiteName,
		mws.Town,
		mws.BDM,
		mws.[Date],
		--mws.ProductID,
		mws.GroupID,
		mws.GroupName,
		mws.IsCask, 
		mws.IsMetric,
		mws.IsTied		
	OPTION (MAXRECURSION 0) -- This prevents SSRS from maxing out at recursion level 100 - allows infinite recursion



	DROP TABLE #Main
	DROP TABLE #SiteProducts	

END
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetVarianceTrendSummaryByUser] TO PUBLIC
    AS [dbo];

