CREATE PROCEDURE [dbo].[GetPumps]
(
	@EDISID	INTEGER
)

AS

SELECT PumpSetup.Pump, 
	Products.[Description] AS Product,
	Products.[ID] AS ProductID,
	PumpSetup.LocationID,
	Locations.[Description] AS Location,
	PumpSetup.InUse,
	PumpSetup.BarPosition,
	Products.CategoryID,
	ProductCategories.Description AS Category,
	SiteKeyTaps.[Type] AS TapType
FROM dbo.PumpSetup
JOIN dbo.Products ON Products.[ID] = PumpSetup.ProductID
JOIN dbo.Locations ON Locations.[ID] = PumpSetup.LocationID
JOIN dbo.ProductCategories ON ProductCategories.[ID] = Products.CategoryID
LEFT JOIN dbo.SiteKeyTaps ON SiteKeyTaps.Pump = PumpSetup.Pump AND SiteKeyTaps.EDISID = @EDISID
WHERE PumpSetup.EDISID = @EDISID
AND ValidTo IS NULL
ORDER BY PumpSetup.Pump

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetPumps] TO PUBLIC
    AS [dbo];

