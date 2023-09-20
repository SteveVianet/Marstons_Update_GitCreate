CREATE PROCEDURE art.GetAverageEquipmentTemperaturesByTradingDay
(
	@From DATE,
	@To DATE
)
AS

SELECT	Sites.SiteID,
		Sites.Name AS SiteName,
		CAST(TradingDate AS DATE) AS TradingDate,
		EquipmentTypes.Description + ': ' + ISNULL(EquipmentItems.[Description], '') AS EquipmentName,
		EquipmentItems.ValueLowSpecification,
		EquipmentItems.ValueHighSpecification,
		AVG(EquipmentReadings.Value) AS AverageTempForDay
FROM EquipmentReadings
JOIN EquipmentItems ON EquipmentItems.EDISID = EquipmentReadings.EDISID AND EquipmentItems.InputID = EquipmentReadings.InputID
JOIN EquipmentTypes ON EquipmentTypes.ID = EquipmentItems.EquipmentTypeID
JOIN Sites ON Sites.EDISID = EquipmentReadings.EDISID
WHERE CAST(TradingDate AS DATE) BETWEEN @From AND @To
GROUP BY  Sites.SiteID,
		Sites.Name,
		CAST(TradingDate AS DATE),
		EquipmentTypes.Description + ': ' + ISNULL(EquipmentItems.[Description], ''),
		EquipmentItems.ValueLowSpecification,
		EquipmentItems.ValueHighSpecification
ORDER BY  Sites.SiteID,
		Sites.Name,
		CAST(TradingDate AS DATE) ASC


GO
GRANT EXECUTE
    ON OBJECT::[art].[GetAverageEquipmentTemperaturesByTradingDay] TO PUBLIC
    AS [dbo];

