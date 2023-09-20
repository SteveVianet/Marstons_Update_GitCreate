CREATE PROCEDURE [dbo].[GetTiedProductsForSchedule]
	@Schedule INT,
	@From DATE,
	@To DATE
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @Products TABLE ( Product INT)

	-- Get all products that have ever been associated with the sites in this schedule
	INSERT INTO @Products
  	SELECT Product
	FROM dbo.DispenseActions AS da
	JOIN ScheduleSites AS ss
		ON ss.EDISID = da.EDISID
	WHERE da.TradingDay BETWEEN @From AND DATEADD("d", 6, @To)
	AND ss.ScheduleID = @Schedule
	GROUP BY Product	
	UNION
	SELECT Product
	FROM ScheduleSites AS ss
	JOIN dbo.MasterDates AS md
	  ON md.EDISID = ss.EDISID
	JOIN dbo.Delivery AS d
		ON md.[ID] = d.DeliveryID
	WHERE ss.ScheduleID = @Schedule
		AND md.[Date] BETWEEN @From AND DATEADD("d", 6, @To)
	GROUP BY Product
	UNION
	SELECT Product
	FROM ScheduleSites AS ss
	JOIN dbo.MasterDates AS md
	  ON md.EDISID = ss.EDISID
	JOIN dbo.DLData AS dld
		ON md.[ID] = dld.DownloadID
	WHERE ss.ScheduleID = @Schedule
		AND md.[Date] BETWEEN @From AND DATEADD("d", 6, @To)
	GROUP BY Product
	UNION
	SELECT s.ProductID
	FROM ScheduleSites AS ss
	JOIN dbo.MasterDates AS md
	  ON md.EDISID = ss.EDISID
	JOIN dbo.Stock AS s
		ON md.[ID] = s.MasterDateID
	WHERE ss.ScheduleID = @Schedule
		AND md.[Date] BETWEEN @From AND DATEADD("d", 6, @To)
	GROUP BY s.ProductID
	UNION
	SELECT sl.ProductID
	FROM ScheduleSites AS ss
	JOIN dbo.MasterDates AS md
	  ON md.EDISID = ss.EDISID
	JOIN dbo.Sales  as sl
		ON ss.EDISID = sl.EDISID
	WHERE ss.ScheduleID = @Schedule
		AND md.[Date] BETWEEN @From AND DATEADD("d", 6, @To)
	GROUP BY sl.ProductID
	UNION
	SELECT  p.ProductID
	FROM ScheduleSites AS ss
	JOIN dbo.MasterDates AS md
	  ON md.EDISID = ss.EDISID
	JOIN dbo.PumpSetup AS p
		ON ss.EDISID = p.EDISID
	WHERE ss.ScheduleID = @Schedule
		AND md.[Date] BETWEEN @From AND DATEADD("d", 6, @To)
	GROUP BY p.ProductID
	UNION
	SELECT  spt.ProductID
	FROM ScheduleSites AS ss
	JOIN dbo.MasterDates AS md
	  ON md.EDISID = ss.EDISID
	JOIN dbo.SiteProductTies AS spt
		ON ss.EDISID = spt.EDISID
	WHERE ss.ScheduleID = @Schedule
		AND md.[Date] BETWEEN @From AND DATEADD("d", 6, @To)
	GROUP BY spt.ProductID

	------- Find which products are tied

	SELECT pdt.ID, pdt.[Description]
	FROM @Products AS p
	JOIN Products AS pdt
	ON p.Product = pdt.[ID]
	WHERE pdt.Tied = 1
	-- Hack to allow products dropdown in SSRS to be optional
	UNION
	SELECT 0, '--All--'
	ORDER BY pdt.[Description]
END
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetTiedProductsForSchedule] TO PUBLIC
    AS [dbo];

