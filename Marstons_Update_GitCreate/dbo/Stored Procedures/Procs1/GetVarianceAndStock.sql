CREATE PROCEDURE [dbo].[GetVarianceAndStock]
	@EDISID INT,
	@From DATE,
	@To DATE
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	WITH Site
	AS
	(
 		SELECT DISTINCT s.EDISID, s2.SiteID as PrimarySite
		FROM Sites AS s
		LEFT JOIN (
			SELECT SiteGroupID,EDISID
			FROM SiteGroupSites AS s    
			LEFT JOIN SiteGroups AS sg ON s.SiteGroupID = sg.ID
			WHERE sg.TypeID = 1
		) AS sgs
			ON sgs.EDISID = s.EDISID
		LEFT JOIN SiteGroupSites AS sgs2 ON sgs2.SiteGroupID = sgs.SiteGroupID AND sgs2.IsPrimary = 1
		JOIN Sites AS s2 ON s.EDISID = COALESCE(sgs2.EDISID, s.EDISID)
		WHERE s.EDISID = @EDISID
	),
	-- Get 
	StockTake
	AS
	(
		SELECT md.Date, s.*
		FROM Stock as s
		JOIN MasterDates AS md
			ON md.ID = s.MasterDateID
		JOIN ( SELECT md.EDISID, s.ProductID, MAX(md.Date) AS LatestStockDate
				FROM Stock as s
				JOIN MasterDates AS md
					ON md.ID = s.MasterDateID
				GROUP BY md.EDISID, s.ProductID
			) AS s2
			ON s2.EDISID = md.EDISID AND s2.ProductID = s.ProductID
		WHERE md.EDISID = @EDISID 
			AND md.Date = s2.LatestStockDate
			AND md.Date BETWEEN @From AND @To
	),
	Dispensed
	AS
	(
		SELECT 
			dld.Product,
			p.Description AS ProductName,
			p.IsCask,
			pgp2.ProductGroupID AS GroupID,
			pgp2.Description AS GroupName,		
			SUM(dld.Quantity) AS DispensedQuantity,
			p.IsMetric
		FROM MasterDates AS md
		JOIN DLData AS dld
			ON dld.DownloadID = md.ID
		LEFT JOIN StockTake AS st
			ON st.ProductID = dld.Product
		JOIN Products AS p
			ON p.ID = dld.Product
		LEFT JOIN (
				SELECT * 
				FROM ProductGroupProducts AS pgp 
				JOIN ProductGroups AS pg
					ON pg.ID = pgp.ProductGroupID
				WHERE pg.TypeID = 1
			) AS pgp2
			ON pgp2.ProductID = p.ID
		-- Calculate data either from last stock take date or @From, if no stock take in report period
		WHERE md.Date BETWEEN COALESCE(st.Date, @From) AND @To
			AND md.EDISID = @EDISID
		GROUP BY dld.Product, p.Description, pgp2.ProductGroupID, pgp2.Description,  p.IsCask, p.IsMetric
	),
	Delivered
	AS
	(
		SELECT
			del.Product,
			p.Description AS ProductName,
			p.IsCask,
			p.IsMetric,
			pgp2.ProductGroupID AS GroupID,
			pgp2.Description AS GroupName,		
			SUM(del.Quantity) * 8 AS DeliveredQuantity			
		FROM MasterDates AS md
		JOIN Delivery AS del
			ON del.DeliveryID = md.ID
		JOIN Products AS p
			ON p.ID = del.Product
		LEFT JOIN StockTake AS st
			ON st.ProductID = del.Product
		LEFT JOIN (
				SELECT * 
				FROM ProductGroupProducts AS pgp 
				JOIN ProductGroups AS pg
					ON pg.ID = pgp.ProductGroupID
				WHERE pg.TypeID = 1
			) AS pgp2
			ON pgp2.ProductID = p.ID
		-- Calculate data either from last stock take date or @From, if no stock take in report period
		WHERE md.Date BETWEEN COALESCE(st.Date, @From) AND @To
			AND md.EDISID = @EDISID
		GROUP BY del.Product, p.Description, pgp2.ProductGroupID, pgp2.Description,  p.IsCask, p.IsMetric
	), 
	--Calculate Variance
	StockAndVariance
	AS
	(
		SELECT 
			COALESCE(del.Product, dis.Product) AS ProductID,
			COALESCE(del.ProductName, dis.ProductName) AS ProductName,
			COALESCE(del.GroupID, dis.GroupID) AS GroupID,
			COALESCE(del.GroupName, dis.GroupName) AS GroupName,
			dis.DispensedQuantity,
			del.DeliveredQuantity,		
			(ISNULL(del.DeliveredQuantity, 0) - ISNULL(dis.DispensedQuantity, 0))  AS Variance,
			st.Date AS StockDate,
			COALESCE(del.IsCask, dis.IsCask) AS IsCask,
			COALESCE(del.IsMetric, dis.IsMetric) AS IsMetric
		FROM Dispensed AS dis
		FULL JOIN Delivered AS del
			ON del.Product = dis.Product
		LEFT JOIN StockTake AS st
				ON st.ProductID = COALESCE(del.Product,	dis.Product)
	)
	

	-- ## Main Query ##

	SELECT sv.Product, SUM(sv.Variance)
	FROM (
		SELECT 

			-- Get the product name depending on whether it is a cask or grouped product, or single product
			CASE v.IsCask
				WHEN 1 THEN 'Cask Products'
				ELSE COALESCE(v.GroupName, v.ProductName)
			END AS Product,
			-- Get the sum depending on whether it is a cask or grouped product, or single product
			SUM(v.Variance) AS Variance
		FROM StockAndVariance AS v
		GROUP BY COALESCE(v.GroupID, v.ProductID), v.IsCask, COALESCE(v.GroupName, v.ProductName)
	) AS sv
	GROUP BY sv.Product

END
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetVarianceAndStock] TO PUBLIC
    AS [dbo];

