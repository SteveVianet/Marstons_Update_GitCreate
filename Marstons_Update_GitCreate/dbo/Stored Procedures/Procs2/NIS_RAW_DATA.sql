CREATE PROCEDURE dbo.NIS_RAW_DATA
(	
	@EDISID	AS	INT,
	@DDATE	AS	DATETIME
)
AS
SELECT     dbo.MasterDates.EDISID, dbo.MasterDates.[Date] AS DDate, dbo.DLData.Shift AS ShiftNo, dbo.DLData.Pump AS FontNo, 
                      dbo.DLData.Product AS ProductID, dbo.DLData.Quantity AS Volume, 'Dispense' AS Type
FROM         dbo.DLData INNER JOIN
                      dbo.MasterDates ON dbo.DLData.DownloadID = dbo.MasterDates.ID
WHERE     (dbo.MasterDates.EDISID = @EDISID) AND (dbo.MasterDates.[Date] = @DDATE) AND (dbo.DLData.Quantity > 0.01)

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[NIS_RAW_DATA] TO PUBLIC
    AS [dbo];

