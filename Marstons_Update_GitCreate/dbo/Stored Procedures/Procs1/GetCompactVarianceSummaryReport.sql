CREATE PROCEDURE [dbo].[GetCompactVarianceSummaryReport]
(
	@ScheduleID 	INT  = NULL,
	@EDISID INT = NULL,
	@From 	SMALLDATETIME,
	@To 		SMALLDATETIME,
	@IgnoreOnlineDates BIT,
	@Product INT = 0
)

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.

SET NOCOUNT ON
SET DATEFIRST 1

DECLARE @Dispensed TABLE	( 
	[Date] DATE,
	EDISID INT,
	Dispensed FLOAT
)

DECLARE @Delivered TABLE	( 
	[Date] DATE,
	EDISID INT,
	Delivered FLOAT
)

INSERT INTO @Dispensed
SELECT md.[Date], ss.EDISID, 
	SUM(dld.Quantity) AS Dispensed
FROM (SELECT DISTINCT EDISID
		FROM ScheduleSites 
		WHERE (ScheduleID = @ScheduleID OR @ScheduleID IS NULL)
	AND (EDISID = @EDISID OR @EDISID IS NULL)
	) AS ss
JOIN MasterDates as md
	ON md.EDISID = ss.EDISID
JOIN Sites AS s
	ON s.EDISID = ss.EDISID
JOIN DLData AS dld
	ON md.[ID] = dld.DownloadID
JOIN Products AS p
	ON p.[ID] = dld.Product
LEFT JOIN SiteProductTies AS spt
	ON md.EDISID = spt.EDISID AND dld.Product = spt.ProductID
LEFT JOIN SiteProductCategoryTies AS spct
	ON md.EDISID = spct.EDISID AND p.CategoryID = spct.ProductCategoryID
WHERE 
	-- The data manipulation is because the users select the beginning Monday of the week they are inteerested in.
	-- but expect to see data up until the following Sunday
	 md.[Date] BETWEEN @From AND @To
	AND COALESCE(spt.Tied, spct.Tied, p.Tied) = 1
	AND (p.ID = @Product OR @Product = 0)
	AND (md.[Date] >= s.SiteOnline OR @IgnoreOnlineDates = 1)
GROUP BY ss.EDISID, md.[Date]

INSERT INTO @Delivered
SELECT md.[Date], ss.EDISID,
	(SUM(del.Quantity) * 8) AS Delivered --Stored in Gallons - converting to pints
FROM (SELECT DISTINCT EDISID
		FROM ScheduleSites 
		WHERE (ScheduleID = @ScheduleID OR @ScheduleID IS NULL)
	AND (EDISID = @EDISID OR @EDISID IS NULL)
	) AS ss
JOIN MasterDates as md
	ON md.EDISID = ss.EDISID
JOIN Sites AS s
	ON s.EDISID = ss.EDISID
JOIN Delivery AS del
	ON md.[ID] = del.DeliveryID
JOIN Products AS p
	ON p.[ID] = del.Product
LEFT JOIN SiteProductTies AS spt
	ON md.EDISID = spt.EDISID AND del.Product = spt.ProductID
LEFT JOIN SiteProductCategoryTies AS spct
	ON md.EDISID = spct.EDISID AND p.CategoryID = spct.ProductCategoryID
WHERE 
	-- The data manipulation is because the users select the beginning Monday of the week they are inteerested in.
	-- but expect to see data up until the following Sunday
	md.[Date] BETWEEN @From AND @To
	AND COALESCE(spt.Tied, spct.Tied, p.Tied) = 1
	AND (p.ID = @Product OR @Product = 0)
GROUP BY ss.EDISID, md.[Date]

SELECT s.SiteID, s.Name,
	Dis.[Date] AS [Date],
	ISNULL(ROUND(SUM(Dis.Dispensed), 2), 0) AS Dispensed,
	ISNULL(ROUND(SUM(Del.Delivered), 2), 0) AS Delivered,
	(ISNULL(ROUND(SUM(Del.Delivered), 2), 0) - ISNULL(ROUND(SUM(Dis.Dispensed), 2), 0)) AS Variance
FROM @Dispensed AS Dis
LEFT JOIN @Delivered AS Del 
	ON Dis.[Date] = Del.[Date] AND Dis.EDISID = Del.EDISID
JOIN Sites AS s
	ON Dis.EDISID = s.EDISID
GROUP BY s.SiteID, s.Name, Dis.Date
ORDER BY Dis.[Date]

END
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetCompactVarianceSummaryReport] TO PUBLIC
    AS [dbo];

