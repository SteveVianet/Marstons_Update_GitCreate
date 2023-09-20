---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE GetTotalPumpDispensed
(
	@EDISID	INT,
	@Pump		INT,
	@From		DATETIME,
	@To		DATETIME
)

AS

SELECT SUM(Quantity)  AS TotalDispensed
FROM dbo.DLData
JOIN dbo.MasterDates ON MasterDates.[ID] = DLData.DownloadID
JOIN dbo.Sites ON Sites.EDISID = MasterDates.EDISID
WHERE Sites.EDISID = @EDISID
AND DLData.Pump = @Pump
AND MasterDates.[Date] BETWEEN @From AND @To
AND MasterDates.[Date] >= Sites.SiteOnline


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetTotalPumpDispensed] TO PUBLIC
    AS [dbo];

