CREATE PROCEDURE [dbo].[VarianceTrendSummaryVRSCAMReport] (
	@EDISISID INT = NULL,
	@ScheduleID INT = NULL,
	@From DATE,
	@To DATE,
	@WeeksPriorToCumulative INT = 3
	)
AS
BEGIN

	--Get Multi-Cellar Sites
	SET NOCOUNT ON;

	DECLARE @Sites TABLE (
    EDISID INT,
    PrimarySiteID VARCHAR(50),
    PrimarySiteName VARCHAR(50),
    Town  VARCHAR(50)
	)
 
	INSERT INTO @Sites
 
	SELECT DISTINCT ss.EDISID, s.SiteID, s.Name,
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
		AND (ss.EDISID = @EDISISID OR @EDISISID IS NULL)


	-- Get products by group and assign primary product
	CREATE TABLE #SiteProducts (
		PrimarySiteID VARCHAR(50),
		PrimarySiteName VARCHAR(50),
		Town VARCHAR(50),
		DateID INT,
		[Date] DATE,
		ProductID INT,
		/*ProductName VARCHAR(50),
		CategoryID INT,*/
		GroupID INT,
		GroupName VARCHAR(50),
		IsCask BIT,
		IsMetric BIT,
		IsTied BIT
		)

	INSERT INTO #SiteProducts 
	SELECT s.PrimarySiteID, 
		s.PrimarySiteName, 
		s.Town, 
		md.ID,
		md.[Date],
		ddp.Product,
		/*p.ID,
		p.[Description],
		p.CategoryID,*/
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
	WHERE md.[Date] BETWEEN DATEADD(WK,-@WeeksPriorToCumulative,@From) AND @To

	-- ### Main Query ###

	SELECT sp.PrimarySiteID,
		sp.PrimarySiteName,
		sp.Town,
		sp.[Date],
		COALESCE(sp.GroupID, sp.ProductID) AS GroupID,
		sp.GroupName, 
		sp.IsCask, 
		sp.IsMetric,
		sp.IsTied,
		dis.Quantity AS Dispensed,
		del.Quantity AS Delivered 
	FROM #SiteProducts AS sp
	LEFT JOIN (SELECT dld.DownloadID, dld.Product, SUM(dld.Quantity) As Quantity
				FROM DLData AS dld
				GROUP BY dld.DownloadID, dld.Product
				) AS dis
		ON dis.DownloadID = sp.DateID AND dis.Product = sp.ProductID
	LEFT JOIN (SELECT d.DeliveryID, d.Product, SUM(d.Quantity)*8 As Quantity -- Delivered stored as gallons - converting to pints
				FROM Delivery AS d
				GROUP BY d.DeliveryID, d.Product
				) AS del
		ON del.DeliveryID = sp.DateID AND del.Product = sp.ProductID

	UNION ALL
	-- Add a list of all dates between the range given for every product for every site - ensures all columns show in SSRS
	SELECT sp.PrimarySiteID,
		sp.PrimarySiteName,
		sp.Town,
		cal.CalendarDate,
		sp.GroupID,
		sp.GroupName, 
		sp.IsCask, 
		sp.IsMetric,
		sp.IsTied,
		0 AS Dispensed,
		0 AS Delivered
    FROM  (SELECT PrimarySiteID,
				PrimarySiteName,
				Town,
				COALESCE(GroupID, ProductID) AS GroupID,
				GroupName,
				IsCask, 
				IsMetric,
				IsTied
			FROM #SiteProducts
			GROUP BY PrimarySiteID,	PrimarySiteName, Town, COALESCE(GroupID, ProductID),  GroupName, IsCask, IsMetric, IsTied
			) AS sp
	CROSS JOIN (SELECT CalendarDate
				FROM Calendar
				WHERE CalendarDate BETWEEN DATEADD(WK,-@WeeksPriorToCumulative,@From) AND @To) AS cal
	ORDER BY sp.[Date]


	DROP TABLE #SiteProducts

END
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[VarianceTrendSummaryVRSCAMReport] TO PUBLIC
    AS [dbo];

