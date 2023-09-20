CREATE PROCEDURE [dbo].[GetVarianceTrendSummary] (
	@EDISID INT = NULL,
	@ScheduleID INT = NULL,
	@From DATE,
	@To DATE
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
    Town  VARCHAR(50)
	)
 
	INSERT INTO @Sites 
	SELECT DISTINCT ss.EDISID, s.EDISID, s.SiteID, s.Name,
        CASE
            WHEN Address3 = '' AND Address2 = '' THEN Address1
            WHEN Address3 = '' THEN Address2
            ELSE Address3
        END AS Town
    FROM ScheduleSites AS ss
    LEFT JOIN (
		SELECT SiteGroupID,EDISID
		FROM SiteGroupSites AS s    
		LEFT JOIN SiteGroups AS sg
			ON s.SiteGroupID = sg.ID
		WHERE sg.TypeID = 1
    ) AS sgs
		ON sgs.EDISID = ss.EDISID
	LEFT JOIN SiteGroupSites AS sgs2
		ON sgs2.SiteGroupID = sgs.SiteGroupID AND sgs2.IsPrimary = 1
    JOIN Sites AS s
		ON s.EDISID = COALESCE(sgs2.EDISID, ss.EDISID)
    WHERE (ss.ScheduleID = @ScheduleID	OR @ScheduleID IS NULL)
		AND (s.EDISID = @EDISID OR @EDISID IS NULL)


	-- Get products by group and assign primary product
	CREATE TABLE #SiteProducts (
		EDISID INT,
		PrimarySiteID VARCHAR(50),
		PrimarySiteName VARCHAR(50),
		Town VARCHAR(50),
		/*DateID INT,
		[Date] DATE,*/
		ProductID INT,
		GroupID INT,
		GroupName VARCHAR(50),
		IsCask BIT,
		IsMetric BIT,
		IsTied BIT
		)

	INSERT INTO #SiteProducts 
	SELECT DISTINCT s.EDISID, 
		s.PrimarySiteID, 
		s.PrimarySiteName, 
		s.Town, 
		/*md.ID,
		md.[Date],*/
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

	-- ### Main Query ###

	SELECT 
	sp.EDISID,
	sp.PrimarySiteID,
		sp.PrimarySiteName,
		sp.Town,
		cal.[CalendarDate],
		md.ID,
		sp.ProductID,
		COALESCE(sp.GroupID, sp.ProductID) AS GroupID,
		sp.GroupName, 
		sp.IsCask, 
		sp.IsMetric,
		sp.IsTied,
		dis.Quantity AS Dispensed,
		del.Quantity AS Delivered 
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
	LEFT JOIN (SELECT d.DeliveryID, d.Product, SUM(d.Quantity)*8 As Quantity -- Delivered stored as gallons - converting to pints
				FROM Delivery AS d
				GROUP BY d.DeliveryID, d.Product
				) AS del
		ON del.DeliveryID = md.ID AND del.Product = sp.ProductID
	ORDER BY cal.CalendarDate


	DROP TABLE #SiteProducts

END
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetVarianceTrendSummary] TO PUBLIC
    AS [dbo];

