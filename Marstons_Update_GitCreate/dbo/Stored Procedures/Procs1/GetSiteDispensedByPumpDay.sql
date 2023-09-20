CREATE PROCEDURE [dbo].[GetSiteDispensedByPumpDay]
(
	@EDISID	INT,
	@From	DATETIME,
	@To	DATETIME,
	@Pump		INT = NULL,
	@ProductID	INT = NULL
)

AS

SET NOCOUNT ON

DECLARE @MasterDates TABLE([ID] INT NOT NULL, EDISID INT NOT NULL, [Date] DATETIME NOT NULL)

INSERT INTO @MasterDates
([ID], EDISID, [Date])
SELECT [ID], MasterDates.EDISID, [Date]
FROM MasterDates
JOIN Sites ON Sites.EDISID = MasterDates.EDISID
WHERE MasterDates.EDISID = @EDISID
AND MasterDates.[Date] BETWEEN @From AND @To
AND MasterDates.[Date] >= Sites.SiteOnline

SELECT	MasterDates.[Date],
	DLData.Pump,
	SUM(DLData.Quantity) AS Quantity
FROM dbo.DLData
JOIN @MasterDates AS MasterDates ON MasterDates.ID = DLData.DownloadID
WHERE (DLData.Pump = @Pump OR @Pump IS NULL)
AND (DLData.Product = @ProductID OR @ProductID IS NULL)
GROUP BY MasterDates.[Date], DLData.Pump

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSiteDispensedByPumpDay] TO PUBLIC
    AS [dbo];

