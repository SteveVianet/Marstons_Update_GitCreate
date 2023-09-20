CREATE PROCEDURE [dbo].[GetSiteDispensedByPumpDay2]
(
	@EDISID	INT,
	@From	DATETIME,
	@To	DATETIME,
	@Pump		INT = NULL,
	@ProductID	INT = NULL
)

AS
BEGIN
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

SELECT	
	MasterDates.[Date],
	PumpSetup.Pump,
	PumpSetup.ProductID as ProductID,
	PumpSetup.ValidFrom,
	PumpSetup.ValidTo,
	Products.Description as Product,
	Products.IsCask,
	Products.IsMetric,
	PumpSetup.LocationID as LocationID,
	Locations.Description as Location,
	DLData.Shift,
	SUM(DLData.Quantity) AS Quantity
FROM @MasterDates AS MasterDates
JOIN PumpSetup ON  PumpSetup.EDISID = MasterDates.EDISID
LEFT JOIN dbo.DLData on DLData.Pump = PumpSetup.Pump AND DLData.Product = PumpSetup.ProductID AND DLData.DownloadID = MasterDates.ID
LEFT JOIN Products on Products.ID = PumpSetup.ProductID
LEFT JOIN Locations on PumpSetup.LocationID = Locations.ID
-- Always get the current font setup
WHERE  (PumpSetup.ValidFrom <= GETDATE() and (PumpSetup.ValidTo>= GETDATE() OR PumpSetup.ValidTo IS NULL)) AND (PumpSetup.Pump = @Pump OR @Pump IS NULL)
	AND (DLData.Product = @ProductID OR @ProductID IS NULL)
GROUP BY MasterDates.[Date], PumpSetup.ValidFrom, PumpSetup.ValidTo, PumpSetup.EDISID, PumpSetup.Pump, PumpSetup.LocationID, DLData.Pump, PumpSetup.ProductID, Products.Description, Products.IsCask, Products.IsMetric, Locations.Description, DLData.Shift
END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSiteDispensedByPumpDay2] TO PUBLIC
    AS [dbo];

