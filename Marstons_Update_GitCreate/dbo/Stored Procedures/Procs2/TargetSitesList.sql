CREATE PROCEDURE [dbo].[TargetSitesList]
	@UserID INT, 
	@SiteTrendTotalLimitFilter INT,
	@SiteTrendKegLimitFilter INT,
	@SiteTrendCaskLimitFilter INT,
	@ShowHidden BIT = 0,
	@ShowClosedSites BIT = 0,
	@Units FLOAT = 1
	
	
AS
BEGIN
	
	SET NOCOUNT ON;
	SET DATEFIRST 1

	DECLARE @To DATETIME = GETDATE()

	DECLARE @Variances TABLE (
		EDISID INT,
		WeekCommencing DATE,
		Delivered FLOAT, 
		Dispensed FLOAT, 
		Variance FLOAT
		)

	INSERT INTO @Variances
	SELECT 
		pc.EDISID,
		WeekCommencing,
		SUM(Delivered) AS Delivered,
		SUM(Dispensed) AS Dispensed,
		SUM(Variance) AS Varaiance
	FROM [dbo].[PeriodCacheVariance] AS pc
	  INNER JOIN UserSites AS us ON pc.EDISID = us.EDISID and us.UserID = @UserID
	WHERE us.UserID = @UserID 
		 AND WeekCommencing Between DATEADD(week, -52,'2016-06-12')  AND DATEADD(WEEK, -18, @To)
	GROUP BY  WeekCommencing,  pc.EDISID
	ORDER BY WeekCommencing

  DECLARE @Percentages TABLE (
	EDISID INT,
	WeekCommencing DATE,
	Delivered FLOAT, 
	Dispensed FLOAT, 
	Variance FLOAT,
	Percentage FLOAT,
	PercentageOver100 FLOAT
	)

  INSERT INTO @Percentages
  SELECT 
	EDISID,
	WeekCommencing,
	Delivered,
	Dispensed,
	Variance,
	(Delivered / NULLIF(Dispensed,0)) *100 AS Percentage,
	CASE
		WHEN ((Delivered / NULLIF(Dispensed,0)) *100) > 100 AND ((Delivered / NULLIF(Dispensed,0)) *100) < 200
			THEN ((Delivered / NULLIF(Dispensed,0)) *100) - 100
		ELSE NULL
	END AS PercentageOver100
  FROM @Variances
	

  --Get the latest change of tenancy date
  CREATE TABLE #cot (
		EDISID INT, 
		COTDate SMALLDATETIME
		)

 -- CREATE NONCLUSTERED INDEX cotIndex 
	--ON SiteComments (HeadingType,[Date]) 
	--INCLUDE (EDISID)

	INSERT INTO #cot
	SELECT s.EDISID, sc.[Date]
	FROM Sites AS s
		INNER JOIN SiteComments AS sc ON s.EDISID = sc.EDISID 
		INNER JOIN UserSites AS us ON s.EDISID = us.EDISID and us.UserID = @UserID
		INNER JOIN (SELECT  s2.EDISID, MAX(sc2.[Date]) AS mDate
				    FROM Sites AS s2 
						INNER JOIN SiteComments AS sc2 ON sc2.EDISID = s2.EDISID
					WHERE sc2.HeadingType = 3004
					GROUP BY s2.EDISID) 
							AS maxDate ON maxDate.EDISID = sc.EDISID
	WHERE sc.HeadingType = 3004
		AND sc.[Date] BETWEEN DATEADD(week, -52,@To)  AND @To
		AND sc.[Date] = maxDate.mDate
		AND us.UserID = @UserID

	--Get the last Invoiced date

	DECLARE @InvoicedDate TABLE(
		EDISID INT,
		InvoiceDate SMALLDATETIME
		)

	INSERT INTO @InvoicedDate
	SELECT Distinct s.EDISID,
			svi.ChargeDate AS InvoiceDate
	FROM Sites AS s
		INNER JOIN SiteVRSInvoiced AS svi ON svi.EDISID = s.EDISID
		INNER JOIN UserSites AS us ON s.EDISID = us.EDISID and us.UserID = @UserID
		INNER JOIN (SELECT  s2.EDISID, MAX(svi2.ChargeDate) AS mDate
				    FROM Sites AS s2 
						INNER JOIN SiteVRSInvoiced AS svi2 ON svi2.EDISID = s2.EDISID
					WHERE svi2.EDISID = s2.EDISID
					GROUP BY s2.EDISID
					) AS invoiceDate ON invoiceDate.EDISID = s.EDISID
	WHERE  us.UserID = @UserID
		AND svi.ChargeDate BETWEEN DATEADD(week, -52,@To)  AND @To
		AND svi.ChargeDate = invoiceDate.mDate
  
  DECLARE @FromDate TABLE(
	EDISID INT,
	WeekCommencing DATE,
	PercentagerOver100 FLOAT
	)

   INSERT INTO @FromDate
   SELECT EDISID, WeekCommencing, PercentageOver100
   FROM @Percentages AS p
   WHERE PercentageOver100 = (SELECT MAX(PercentageOver100) FROM @Percentages as p2 WHERE p.EDISID = p2.EDISID)
   
   DECLARE @Dates TABLE(
	  EDISID INT,
	  COTDate DATE,
	  InvoiceDate DATE,
	  PercentageOver100Date DATE
	  )
	INSERT INTO @Dates
	SELECT DISTINCT
		fd.EDISID,
		COALESCE(DATEADD(wk, DATEDIFF(wk,0,[cot].COTDate), 7),NULL), --Get the Monday of the next week
		COALESCE(DATEADD(wk, DATEDIFF(wk,0,invoice.InvoiceDate), 7),NULL), --Get the Monday of the next week
		fd.WeekCommencing 

	FROM @FromDate AS fd
		LEFT JOIN #cot AS [cot] ON [cot].EDISID = fd.EDISID
		LEFT JOIN @InvoicedDate AS invoice ON invoice.EDISID = fd.EDISID

	--Get Dispensed Data
	CREATE TABLE #Dispensed ( 
		EDISID INT,
		[Date] DATETIME,
		ProductGroupID INT,
		[Description] VARCHAR(100),
		Dispensed FLOAT,
		Delivered FLOAT,
		Variance FLOAT
		)

	INSERT INTO #Dispensed
	SELECT	
		s.EDISID,
		pcv.WeekCommencing,
		COALESCE(pgp.ProductGroupID,p.ID) AS ProductGroupID,
		COALESCE(pg.[Description],p.[Description])AS [Description],
		ISNULL(SUM(pcv.Dispensed * 0.125),0) AS Dispensed,
		ISNULL(SUM(pcv.Delivered * 0.125),0) AS Delivered,
		ISNULL(SUM(pcv.Variance * 0.125),0) AS Variance
	FROM PeriodCacheVariance as pcv
		INNER JOIN Sites AS s ON s.EDISID = pcv.EDISID
		LEFT JOIN Products AS p ON p.ID = pcv.ProductID
		LEFT JOIN ProductGroupProducts AS pgp ON pgp.ProductID = p.ID
		LEFT JOIN ProductGroups AS pg ON pg.ID = pgp.ProductGroupID
		LEFT JOIN SiteProductTies AS spt ON  spt.EDISID =s.EDISID AND spt.ProductID = p.[ID]
		LEFT JOIN SiteProductCategoryTies AS spct ON spct.EDISID = s.EDISID AND spct.ProductCategoryID = p.CategoryID
		INNER JOIN @Dates AS d ON d.EDISID = s.EDISID
		INNER JOIN UserSites AS us ON s.EDISID = us.EDISID and us.UserID = @UserID
	WHERE us.UserID = @UserID
		 AND pcv.WeekCommencing BETWEEN COALESCE(d.COTDate, d.InvoiceDate, d.PercentageOver100Date) and @To
		AND p.IsCask = 0
		AND COALESCE(pgp.ProductGroupID,p.ID) != 1
		AND COALESCE(spt.Tied, spct.Tied, p.Tied) = 1
	GROUP BY s.EDISID, pcv.WeekCommencing, COALESCE(pgp.ProductGroupID,p.ID), COALESCE(pg.[Description],p.[Description])

	--Consolidated Casks -5%
	INSERT INTO #Dispensed
	SELECT	
		s.EDISID,
		pcv.WeekCommencing,
		1000 AS ProductGroupID,
		'Casks' AS Description,
		ISNULL(SUM(pcv.Dispensed *  0.125)*0.95,0) AS Dispensed,
		ISNULL(SUM(pcv.Delivered * 0.125),0) AS Delivered,
		ISNULL(SUM(pcv.Delivered * 0.125),0) - ISNULL(SUM(pcv.Dispensed *  0.125)*0.95,0) AS Variance
	FROM PeriodCacheVariance as pcv
		INNER JOIN Sites AS s ON s.EDISID = pcv.EDISID
		LEFT JOIN Products AS p ON p.ID = pcv.ProductID
		LEFT JOIN ProductGroupProducts AS pgp ON pgp.ProductID = p.ID
		LEFT JOIN ProductGroups AS pg ON pg.ID = pgp.ProductGroupID
		LEFT JOIN SiteProductTies AS spt ON  spt.EDISID =s.EDISID AND spt.ProductID = p.[ID]
		LEFT JOIN SiteProductCategoryTies AS spct ON spct.EDISID = s.EDISID AND spct.ProductCategoryID = p.CategoryID
		INNER JOIN @Dates AS d ON d.EDISID = s.EDISID
		INNER JOIN UserSites AS us ON s.EDISID = us.EDISID and us.UserID = @UserID
	WHERE us.UserID = @UserID
		 AND pcv.WeekCommencing BETWEEN COALESCE(d.COTDate, d.InvoiceDate, d.PercentageOver100Date) and @To
		AND p.IsCask = 1
		AND (pgp.IsPrimary = 0 OR pgp.IsPrimary IS NULL OR pgp.ProductGroupID = 19)
		AND COALESCE(spt.Tied, spct.Tied, p.Tied) = 1
	GROUP BY s.EDISID, pcv.WeekCommencing

	--Get variance WEEKLY by product

	CREATE TABLE #CumlativeVariance (
		RowNumber INT,
		EDISID INT,
		SiteID VARCHAR(50),
		Name VARCHAR(100),
		[Date] DATETIME,
		ProductGroupID INT,
		ProductDescription VARCHAR(200),
		QuantityDispensed FLOAT,
		QuantityDelivered FLOAT,
		ProductVariance FLOAT,
		CumlativeVariance FLOAT,
		Trending BIT,
		Trend FLOAT,
		TrendTotal FLOAT
		)

	INSERT INTO #CumlativeVariance 
	(RowNumber,EDISID, SiteID,Name,[Date],ProductGroupID,ProductDescription,QuantityDispensed,QuantityDelivered,ProductVariance)
	SELECT 
		ROW_NUMBER() OVER (ORDER BY d.[Date]) AS id,
		s.EDISID,
		s.SiteID,
		s.Name,
		d.[Date],
		d.ProductGroupID,
		d.[Description],
		ISNULL(d.Dispensed, 0) AS Dispensed,
		ISNULL(d.Delivered, 0) AS Delivered,
		ISNULL(d.Variance,0) AS Variance
	FROM Sites AS s
		INNER JOIN #Dispensed AS d ON d.EDISID = s.EDISID
	
	
	--Get the Cumulative Variance 

	
	--Calculate the Cumlative Variance & Trend

	;WITH [V] AS 
	(	SELECT
				cv.EDISID, 
				cv.[Date],
				cv.ProductGroupID,
			   cv.ProductDescription,
			   cv.ProductVariance,
			   ROW_NUMBER() OVER (ORDER BY cv.EDISID, cv.ProductGroupID, cv.[Date]) AS [RowNum]
		FROM #CumlativeVariance AS cv
	),
	[W] AS
	(
		SELECT 
			EDISID,
			[Date],
				[V].ProductGroupID,
			   [V].ProductDescription,
			   ProductVariance,
			   [V].RowNum,
			   CV = ProductVariance,
			   Trend= ProductVariance 
		FROM [V]
			INNER JOIN (SELECT ProductGroupID,
								MIN(RowNum) AS RowNum 
						FROM [V] 
						GROUP BY EDISID, ProductGroupID 
						) AS X ON [V].RowNum = [X].RowNum

		UNION ALL

		SELECT 
			[V].EDISID,
			[V].[Date],
			[V].ProductGroupID,
			[V].ProductDescription,
			[V].ProductVariance,
			[V].RowNum,
			[W].CV + [V].ProductVariance,
			CASE 
				WHEN [V].ProductVariance < 0 THEN [W].Trend + [V].ProductVariance
				ELSE 
					CASE
						WHEN [W].Trend >=0 THEN [W].Trend + [V].ProductVariance
						WHEN [W].Trend >= -5 THEN [W].Trend + [V].ProductVariance
						ELSE [V].ProductVariance
					END
			END AS Trend 
		FROM [W]
			INNER JOIN [V] ON [V].RowNum = ([W].RowNum +1) AND [V].ProductGroupID = [W].ProductGroupID AND [V].EDISID = [W].EDISID
	)

	UPDATE #CumlativeVariance
	SET CumlativeVariance = [CV].Cumlative,
		Trend = [CV].Trend,
		Trending = CASE WHEN [CV].Trend < -5 THEN 1 ELSE 0 END
	FROM #CumlativeVariance AS [V]
		INNER JOIN (SELECT  [EDISID],
							[Date],	
							ProductGroupID,
						    ProductDescription,
							ProductVariance,
							Cumlative = [CV],
							Trend,
							RowNum
					FROM [W]) AS [CV] ON [V].[Date] = [CV].[Date] AND [V].ProductGroupID = [CV].ProductGroupID AND [V].EDISID = [CV].EDISID
	OPTION (MAXRECURSION 32767)

	--Set the Trend Totals 

	UPDATE [V1]
	SET V1.TrendTotal = 
		CASE 
			WHEN V1.Trending = 1 AND V2.Trending = 0 THEN V1.Trend
		ELSE NULL
		END
	FROM #CumlativeVariance AS V1
		INNER JOIN #CumlativeVariance AS V2 ON V1.[Date] = DATEADD(DAY, -7, V2.[Date]) AND V1.ProductGroupID = V2.ProductGroupID AND V1.EDISID = V2.EDISID

	--Close Hanging Trends 

	UPDATE [cv]
	SET TrendTotal = Trend
	FROM #CumlativeVariance AS cv
		INNER JOIN (
			SELECT PotentialHanging.EDISID, PotentialHanging.HangingTrendWeek, PotentialHanging.ProductGroupID
			FROM ( 
					SELECT EDISID, MAX([Date]) AS HangingTrendWeek, ProductGroupID
					FROM #CumlativeVariance AS cv
					WHERE Trending = 1
						AND TrendTotal IS NULL
					GROUP BY EDISID, ProductGroupID) AS PotentialHanging 

					LEFT JOIN (
						SELECT EDISID, [Date] AS CompletedTrendWeek, ProductGroupID
						FROM #CumlativeVariance
						WHERE Trending = 1
							AND TrendTotal IS NOT NULL
						GROUP BY EDISID, ProductGroupID, Date) AS CompletedTrends ON PotentialHanging.ProductGroupID = CompletedTrends.ProductGroupID AND DATEADD(WEEK, 1, PotentialHanging.HangingTrendWeek) = CompletedTrends.CompletedTrendWeek  AND  PotentialHanging.EDISID = CompletedTrends.EDISID 
			WHERE CompletedTrends.CompletedTrendWeek IS NULL ) AS TrendsToClose ON cv.ProductGroupID = TrendsToClose.ProductGroupID AND cv.[Date] = TrendsToClose.HangingTrendWeek AND cv.EDISID = TrendsToClose.EDISID


	--Get the products names and numbers with a negative variance 
	DECLARE @TotalTrendsPerSiteAllProducts TABLE (
		EDISID INT, 
		ProductDescription VARCHAR(100),
		Total INT 
		)

	INSERT INTO @TotalTrendsPerSiteAllProducts 
	SELECT cv.EDISID,
	cv.ProductDescription,
	CASE
		WHEN cv.ProductDescription = 'Casks' AND SUM(cv.TrendTotal) < @SiteTrendCaskLimitFilter
			THEN SUM(cv.TrendTotal)*@Units
		WHEN cv.ProductDescription != 'Casks' AND SUM(cv.TrendTotal) < @SiteTrendKegLimitFilter
			THEN SUM(cv.TrendTotal)*@Units
		ELSE 0
		END AS Total

	FROM #CumlativeVariance AS cv
	GROUP BY cv.ProductDescription, cv.EDISID
	HAVING SUM(cv.TrendTotal) < @SiteTrendKegLimitFilter

	DECLARE @TotalTrendsPerSite TABLE (
		EDISID INT,
		Total FLOAT
		)

	INSERT INTO @TotalTrendsPerSite
	SELECT t.EDISID,SUM(t.Total)*@Units AS Total
	FROM @TotalTrendsPerSiteAllProducts AS t
	GROUP BY t.EDISID

	DECLARE @ProductsWithNegativeTrendTotal TABLE (
		EDISID INT,
		Total FLOAT,
		NegativeProducts VARCHAR(1000)
		)

	INSERT INTO @ProductsWithNegativeTrendTotal
	SELECT 
		s.EDISID, 
		t.Total,
		CVConcatNames.NegProducts
	FROM Sites AS s 
		INNER JOIN #CumlativeVariance as cv ON cv.EDISID = s.EDISID
		INNER JOIN (SELECT DISTINCT
						B.EDISID,
						SUBSTRING(
							(SELECT TotalTrendsPerSiteAllProducts.ProductDescription + ' ' + CONVERT(VARCHAR(1000),TotalTrendsPerSiteAllProducts.Total) + CHAR(10) + CHAR(10) AS [text()]
							 FROM #CumlativeVariance AS A
								INNER JOIN @TotalTrendsPerSiteAllProducts AS TotalTrendsPerSiteAllProducts ON A.EDISID = TotalTrendsPerSiteAllProducts.EDISID
							 WHERE A.EDISID = B.EDISID and TotalTrendsPerSiteAllProducts.Total < @SiteTrendKegLimitFilter
							 GROUP BY TotalTrendsPerSiteAllProducts.ProductDescription, TotalTrendsPerSiteAllProducts.Total
							 ORDER BY TotalTrendsPerSiteAllProducts.Total ASC
							 For XML PATH('')),0,1000) AS NegProducts
					FROM #CumlativeVariance AS B) AS CVConcatNames ON s.EDISID = CVConcatNames.EDISID
		INNER JOIN @TotalTrendsPerSite AS t ON t.EDISID = cv.EDISID
	
	GROUP BY s.EDISID, CVConcatNames.NegProducts, t.Total


    -- Main Select Statement

	SELECT DISTINCT
		cv.SiteID,
		cv.Name,
		CASE 
			WHEN s.Address4 = ''  THEN s.Address3
			ELSE s.Address4
		END AS [Address],
		s.PostCode AS PostCode,
		area.[Description] AS Area,
		r.[Description] AS DBU,
		pwntt.Total,
		pwntt.NegativeProducts,
		ISNULL(CONVERT(VARCHAR(50),d.COTDate),'') AS [COT],
		ISNULL(CONVERT(VARCHAR(50),d.InvoiceDate),'') AS LastInvoiceDate,
		ReportDates.ReportDate
		

	FROM #CumlativeVariance AS cv
		INNER JOIN @ProductsWithNegativeTrendTotal AS pwntt ON pwntt.EDISID = cv.EDISID
		INNER JOIN Sites AS s ON s.EDISID = cv.EDISID
		LEFT JOIN @Dates AS d ON d.EDISID = cv.EDISID
		INNER JOIN (SELECT d2.EDISID,
			 CONVERT(VARCHAR(50), COALESCE(d2.COTDate, d2.InvoiceDate, d2.PercentageOver100Date),106)
			+CONVERT(VARCHAR(50), ' - ')
			+CONVERT(VARCHAR(50), @To,106)
			+CONVERT(VARCHAR(50), ' (') --CHANGE
			+ CONVERT(VARCHAR(50),DATEDIFF(WEEK, COALESCE(d2.COTDate, d2.InvoiceDate, d2.PercentageOver100Date), @To)-1)
			+ CONVERT(VARCHAR(50), ' Weeks)') AS ReportDate --CHANGE TO GETDATE()
		 FROM @Dates AS d2) AS ReportDates ON ReportDates.EDISID = cv.EDISID
		 INNER JOIN Areas as area ON area.ID = s.AreaID
		 INNER JOIN Regions AS r ON r.ID = s.Region
	WHERE pwntt.Total < @SiteTrendTotalLimitFilter
		AND (s.Hidden = 0 or @ShowHidden = 1) 
		AND (s.SiteClosed = 0 or @ShowClosedSites = 1)
	ORDER BY pwntt.Total ASC

	DROP TABLE #cot
	DROP TABLE #Dispensed
	DROP TABLE #CumlativeVariance
END
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[TargetSitesList] TO PUBLIC
    AS [dbo];

