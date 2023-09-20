CREATE PROCEDURE ComparativeRedAlert 
	@ScheduleID INT,
	@From SMALLDATETIME,
	@To SMALLDATETIME,
	@ShowHidden BIT = 0
	
AS
BEGIN
	
SET NOCOUNT ON;

--Get Dispensed Data
DECLARE @dis TABLE	( 
	EDISID INT,
	Dispensed FLOAT
	)

INSERT INTO @dis
SELECT 
	ss.EDISID,
	SUM(dld.Quantity) AS TotalDispensed
FROM DLData AS dld
	INNER JOIN MasterDates as md ON md.[ID] = dld.DownloadID
	INNER JOIN Products AS p ON p.[ID] = dld.Product
	INNER JOIN Sites AS s ON s.EDISID = md.EDISID
	LEFT JOIN SiteProductTies AS spt ON  spt.EDISID =s.EDISID AND spt.ProductID = p.[ID]
	LEFT JOIN SiteProductCategoryTies AS spct ON spct.EDISID = s.EDISID AND p.CategoryID = spct.ProductCategoryID
	INNER JOIN ScheduleSites AS ss On s.EDISID = ss.EDISID
	
WHERE ss.ScheduleID = @ScheduleID
	AND COALESCE(spt.Tied, spct.Tied, p.Tied) = 1
	AND md.[Date] BETWEEN @From AND DATEADD("d", 6, @To)
	AND md.[Date] >= s.SiteOnline
GROUP BY ss.EDISID
order by EDISID

--Get Delivered Data
DECLARE @tempDelivered TABLE(
	EDISID INT,
	Delivered FLOAT
	)

INSERT INTO @tempDelivered
SELECT 
	ss.EDISID,
	SUM(del.Quantity/0.125) AS TotalDelivered
FROM Delivery AS del
	INNER JOIN MasterDates as md ON md.[ID] = del.DeliveryID
	INNER JOIN Sites AS s ON s.EDISID = md.EDISID
	INNER JOIN Products AS p ON p.[ID] = del.Product
	LEFT JOIN SiteProductTies AS spt ON  spt.EDISID =s.EDISID AND spt.ProductID = p.[ID]
	LEFT JOIN SiteProductCategoryTies AS spct ON spct.EDISID = s.EDISID AND p.CategoryID = spct.ProductCategoryID
	INNER JOIN ScheduleSites AS ss On s.EDISID = ss.EDISID
	
WHERE ss.ScheduleID = @ScheduleID
	AND COALESCE(spt.Tied, spct.Tied, p.Tied) = 1
	AND md.[Date] BETWEEN @From AND DATEADD("d", 6, @To)
	AND md.[Date] >= s.SiteOnline
GROUP BY ss.EDISID
order by EDISID

--Get Dispensed Data for Last four weeeks of data range
DECLARE @fourWeeksDis TABLE	( 
	EDISID INT,
	Dispensed FLOAT
	)

INSERT INTO @fourWeeksDis
SELECT 
	ss.EDISID,
	SUM(dld.Quantity) AS TotalDispensed
FROM DLData AS dld
	INNER JOIN MasterDates as md ON md.[ID] = dld.DownloadID
	INNER JOIN Products AS p ON p.[ID] = dld.Product
	INNER JOIN Sites AS s ON s.EDISID = md.EDISID
	LEFT JOIN SiteProductTies AS spt ON  spt.EDISID =s.EDISID AND spt.ProductID = p.[ID]
	LEFT JOIN SiteProductCategoryTies AS spct ON spct.EDISID = s.EDISID AND p.CategoryID = spct.ProductCategoryID
	INNER JOIN ScheduleSites AS ss On s.EDISID = ss.EDISID
	
WHERE ss.ScheduleID = @ScheduleID
	AND COALESCE(spt.Tied, spct.Tied, p.Tied) = 1
	AND md.[Date] BETWEEN DATEADD(week,-4,DATEADD("d", 6, @To)) AND DATEADD("d", 6, @To)
	AND md.[Date] >= s.SiteOnline
GROUP BY ss.EDISID
order by EDISID

--Get Delivered Data for Last four weeeks of data range
DECLARE @fourWeeksDel TABLE	( 
	EDISID INT,
	Delivered FLOAT
	)
INSERT INTO @fourWeeksDel
SELECT 
	ss.EDISID,
	SUM(del.Quantity/0.125) AS TotalDelivered
FROM Delivery AS del
	INNER JOIN MasterDates as md ON md.[ID] = del.DeliveryID
	INNER JOIN Sites AS s ON s.EDISID = md.EDISID
	INNER JOIN Products AS p ON p.[ID] = del.Product
	LEFT JOIN SiteProductTies AS spt ON  spt.EDISID =s.EDISID AND spt.ProductID = p.[ID]
	LEFT JOIN SiteProductCategoryTies AS spct ON spct.EDISID = s.EDISID AND p.CategoryID = spct.ProductCategoryID
	INNER JOIN ScheduleSites AS ss On s.EDISID = ss.EDISID
	
WHERE ss.ScheduleID = @ScheduleID
	AND COALESCE(spt.Tied, spct.Tied, p.Tied) = 1
	AND md.[Date] BETWEEN DATEADD(week,-4,DATEADD("d", 6, @To)) AND DATEADD("d", 6, @To)
	AND md.[Date] >= s.SiteOnline
GROUP BY ss.EDISID
order by EDISID

--Get BDM for each site
DECLARE @BDM TABLE	( 
	ID INT,
	UserName VARCHAR(30),
	EDISID INT
	)
INSERT INTO @BDM
SELECT	u.ID,
		u.UserName,
		s.EDISID
FROM Users As u
	INNER JOIN UserSites as us ON us.UserID = u.ID
	INNER JOIN Sites AS s ON s.EDISID = us.EDISID
WHERE u.UserType = 2

--Get OD for each site
DECLARE @OD TABLE	( 
	ID INT,
	UserName VARCHAR(30),
	EDISID INT
	)
INSERT INTO @OD
SELECT	u.ID,
		u.UserName,
		s.EDISID
FROM Users As u
	INNER JOIN UserSites as us ON us.UserID = u.ID
	INNER JOIN Sites AS s ON s.EDISID = us.EDISID
WHERE u.UserType = '1' and us.EDISID = s.EDISID

DECLARE @Sites TABLE (
	EDISID INT,
	SiteID VARCHAR(50),
	Name VARCHAR(50),
	Address1 VARCHAR(50),
	Address2 VARCHAR(50),
	Address3 VARCHAR(50),
	SiteOnline SMALLDATETIME,
	Hidden BIT
	
)

INSERT INTO @Sites -- Taking into account for Multi Cellar

	SELECT DISTINCT ss.EDISID, s.SiteID, s.Name, s.Address1, s.Address2,s.Address3,s.SiteOnline,s.Hidden
	FROM ScheduleSites AS ss

		LEFT JOIN (
			SELECT SiteGroupID,EDISID
			FROM SiteGroupSites AS s	
				LEFT JOIN SiteGroups AS sg ON s.SiteGroupID = sg.ID
			WHERE sg.TypeID = 1
		) AS sgs ON sgs.EDISID = ss.EDISID

		LEFT JOIN SiteGroupSites AS sgs2 ON sgs2.SiteGroupID = sgs.SiteGroupID AND sgs2.IsPrimary = 1
		INNER JOIN Sites AS s ON s.EDISID = COALESCE(sgs2.EDISID, ss.EDISID)
	WHERE ss.ScheduleID = @ScheduleID

--Main Select Query
SELECT
	s.SiteID,
	s.Name,
	CASE 
		WHEN s.Address3 = '' AND s.Address2 = '' THEN s.Address1
		WHEN s.Address3 = '' THEN s.Address2
		ELSE s.Address3
	END AS Town,

	CASE
		WHEN s.SiteOnline <= @From THEN DATEDIFF(week,@From,DATEADD("d", 6, @To))
		ELSE DATEDIFF(week,s.SiteOnline,DATEADD("d", 6, @To))
	 END AS WeeksOnline, 
	ROUND(ISNULL(d.Dispensed, 0), 2) AS Dispensed,
	ROUND(ISNULL(td.Delivered, 0), 2) AS Delivered,
	ROUND(ISNULL(td.Delivered, 0) - ISNULL(d.Dispensed, 0), 2) AS Variance,
	ROUND(ISNULL(fourDis.Dispensed, 0), 2) AS FourWeekDispensed,
	ROUND(ISNULL(fourDel.Delivered, 0), 2) AS FourWeekDelivered,
	ROUND(ISNULL(fourDel.Delivered, 0) - ISNULL(fourDis.Dispensed, 0), 2) AS FourWeekVariance,
	OD.UserName AS OD,
	BDM.UserName AS BDM,
	s.EDISID
FROM @Sites AS s
	LEFT JOIN @dis AS d ON s.EDISID = d.EDISID
	LEFT JOIN @tempDelivered AS td ON s.EDISID = td.EDISID
	LEFT JOIN UserSites AS us ON s.EDISID = us.EDISID
	LEFT JOIN @fourWeeksDis as fourDis ON s.EDISID = fourDis.EDISID
	LEFT JOIN @fourWeeksDel as fourDel ON s.EDISID = fourDel.EDISID
	LEFT JOIN @BDM as BDM ON us.EDISID = BDM.EDISID
	LEFT JOIN @OD AS OD ON us.EDISID = OD.EDISID
WHERE (s.Hidden = 0 or @ShowHidden = 1) AND (ISNULL(d.Dispensed, 0) > 0 OR ISNULL(td.Delivered,0) > 0)
GROUP BY s.SiteID, s.Name,s.Address1,s.Address2,s.Address3,s.SiteOnline,d.Dispensed,td.Delivered,fourDis.Dispensed, fourDel.Delivered,BDM.UserName, OD.UserName,s.EDISID
ORDER BY Variance
 
END
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[ComparativeRedAlert] TO PUBLIC
    AS [dbo];

