CREATE PROCEDURE [dbo].[GetUserSitesReviewByDate]
(
	@From		datetime,
	@To		datetime,
	@UserID	int
)
AS

SET NOCOUNT ON

DECLARE @OldestStockWeeksBack	INT
DECLARE @Review TABLE 
(
	EDISID			int,
	UserID			int,
	UserName		varchar(256),
	SiteID			varchar(15),
	SiteName		varchar(60),
	Town			varchar(50),
	LastStock		datetime,
	HasStockInPeriod	bit,
	SiteRanking		int,
	BrulinesComment	varchar(8000),
	CustomerComment	varchar(8000),
	VRSComment		varchar(60),
	VRSVisitDate	DateTime,
	Variance		float
	PRIMARY KEY (EDISID)
)

-- fast query for rapid reduction of sites
INSERT INTO @Review (EDISID, UserID, UserName, SiteID, SiteName, Town)
SELECT rus.EDISID, rus.UserID, u.UserName, SiteID, Name,
	COALESCE(NULLIF(Address2,''), NULLIF(Address3,''), NULLIF(Address4,''), '?') AS Town
FROM UserSites AS pus
	JOIN UserSites AS rus
		ON rus.EDISID = pus.EDISID
	JOIN Users AS u
		ON u.ID = rus.UserID
	JOIN Sites AS s
		ON s.EDISID = rus.EDISID
WHERE pus.UserID = @UserID
	AND u.UserType = 2
	AND s.Hidden = 0

UPDATE @Review SET LastStock = ISNULL(LatestStock.MaxDate, 0)
FROM @Review r
	LEFT JOIN ( 
		SELECT EDISID, MAX([Date]) AS MaxDate
		FROM MasterDates
			JOIN Stock
				ON Stock.MasterDateID = MasterDates.[ID]
		GROUP BY EDISID
	) AS LatestStock
		ON LatestStock.EDISID = r.EDISID

SELECT @OldestStockWeeksBack = CAST(PropertyValue AS INTEGER)
FROM Configuration
WHERE PropertyName = 'Oldest Stock Weeks Back'

UPDATE @Review SET HasStockInPeriod = StocksInPeriod.StockInPeriod
FROM @Review AS Review
LEFT JOIN
(
	SELECT EDISID, CASE WHEN LastStock < DATEADD(week, @OldestStockWeeksBack*-1, @From) THEN 0 ELSE 1 END AS StockInPeriod
	FROM @Review AS Review
) AS StocksInPeriod ON StocksInPeriod.EDISID = Review.EDISID

UPDATE @Review SET SiteRanking = srt.ID
FROM @Review r
	JOIN SiteRankings sr
		ON sr.EDISID = r.EDISID
	JOIN (
		SELECT EDISID, MAX(ValidTo) AS ValidTo
		FROM SiteRankings
		WHERE RankingCategoryID = 1
		GROUP BY EDISID
	) AS SiteRank 
		ON SiteRank.ValidTo = sr.ValidTo 
		AND SiteRank.EDISID = sr.EDISID
	JOIN SiteRankingTypes srt 
		ON srt.ID = sr.RankingTypeID
WHERE RankingCategoryID = 1 


UPDATE @Review SET BrulinesComment = (CONVERT(varchar(11), sc.Date, 113) + ': ' + scht.Description + ': ' + sc.Text)
FROM (
	SELECT EDISID, MAX(Date) AS MaxDate
	FROM SiteComments
	WHERE Type = 1
		AND Date < GETDATE()
	GROUP BY EDISID
	) x
	JOIN SiteComments sc 
		ON x.EDISID = sc.EDISID
		AND x.MaxDate = sc.Date
		AND Type = 1
	LEFT JOIN SiteCommentHeadingTypes scht
		ON scht.ID = sc.HeadingType
	JOIN @Review AS Tmp
		ON Tmp.EDISID = sc.EDISID


UPDATE @Review SET CustomerComment = (CONVERT(varchar(11), sc.Date, 113) + ': ' + sc.Text)
FROM (
	SELECT EDISID, MAX(Date) AS MaxDate
	FROM SiteComments
	WHERE Type = 2
		AND Date < GETDATE()
	GROUP BY EDISID
	) x
	JOIN SiteComments sc
		ON x.EDISID = sc.EDISID
		AND x.MaxDate = sc.Date
		AND Type = 2
	JOIN @Review AS r
		ON r.EDISID = sc.EDISID


UPDATE @Review SET VRSComment = vot.Description, VRSVisitDate = x.MaxDate
FROM (
	SELECT EDISID, MAX(VisitDate) AS MaxDate
	FROM VisitRecords
	WHERE Deleted = 0
	GROUP BY EDISID
	) x
	JOIN VisitRecords vr 
		ON x.EDISID = vr.EDISID
		AND x.MaxDate = vr.VisitDate
	LEFT JOIN VisitOutcomeTypes vot
		ON vot.ID = vr.VisitOutcomeID
	JOIN @Review AS r
		ON r.EDISID = vr.EDISID


declare @variance table
(
	edisid			int,
	delivered		float,
	dispensed		float,
	primary key ( edisid )
)


insert @variance (edisid)
	select EDISID
	from @Review

update @variance set dispensed = tmp.disp
	from @variance v
		inner join (
			select r.EDISID, (SUM(dis.Quantity) / 8) as disp
			from @Review r
				join MasterDates md on md.EDISID = r.EDISID
				join DLData dis on dis.DownloadID = md.ID
				join Products p on p.ID = dis.Product 
				left join SiteProductTies spt on spt.EDISID = r.EDISID
					and spt.ProductID = p.ID
				left join SiteProductCategoryTies spct on spct.EDISID = r.EDISID
					and spct.ProductCategoryID = p.CategoryID
				Join Sites on Sites.EDISID = r.EDISID
			where coalesce(spt.Tied, spct.Tied, p.Tied) = 1
					and md.Date between @From and @To
					and md.Date >= Sites.SiteOnline
			group by r.EDISID
		) tmp on tmp.EDISID = v.edisid

update @variance set delivered = tmp.del
	from @variance v
		inner join (
			select r.EDISID, SUM(del.Quantity) as del
			from @Review r
				join MasterDates md on md.EDISID = r.EDISID
				join Delivery del on del.DeliveryID = md.ID
				join Products p on p.ID = del.Product 
				left join SiteProductTies spt on spt.EDISID = r.EDISID
					and spt.ProductID = p.ID
				left join SiteProductCategoryTies spct on spct.EDISID = r.EDISID
					and spct.ProductCategoryID = p.CategoryID
				Join Sites on Sites.EDISID = r.EDISID	
			where coalesce(spt.Tied, spct.Tied, p.Tied) = 1
			        and md.Date between @From and @To
			        and md.Date >= Sites.SiteOnline
			group by r.EDISID
		) tmp on tmp.EDISID = v.edisid

update @variance set dispensed = 0.0
where dispensed is null

update @variance set delivered = 0.0
where delivered is null

UPDATE @Review SET Variance = (v.delivered - v.dispensed)
FROM @variance v
	JOIN @Review r
		ON r.EDISID = v.edisid


UPDATE @Review SET Variance = 0.0
WHERE Variance IS NULL

UPDATE @Review SET BrulinesComment = ''
WHERE BrulinesComment IS NULL

UPDATE @Review SET CustomerComment = ''
WHERE CustomerComment IS NULL

UPDATE @Review SET VRSComment = ''
WHERE VRSComment IS NULL


SELECT EDISID, UserID, UserName, SiteID, SiteName, Town, LastStock, HasStockInPeriod, SiteRanking, BrulinesComment, CustomerComment, VRSComment, VRSVisitDate, Variance
FROM @Review
ORDER BY UserID, Variance
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetUserSitesReviewByDate] TO PUBLIC
    AS [dbo];

