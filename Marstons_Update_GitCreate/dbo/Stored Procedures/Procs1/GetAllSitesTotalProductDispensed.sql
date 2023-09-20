CREATE PROCEDURE dbo.GetAllSitesTotalProductDispensed
(
	@ProductID	INT,
	@From		DATETIME,
	@To		DATETIME
)

AS

SELECT SUM(Quantity) AS TotalDispensed
FROM dbo.DLData
JOIN dbo.MasterDates ON MasterDates.[ID] = DLData.DownloadID
WHERE DLData.Product = @ProductID
AND MasterDates.[Date] BETWEEN @From AND @To


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetAllSitesTotalProductDispensed] TO PUBLIC
    AS [dbo];

