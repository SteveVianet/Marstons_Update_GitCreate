CREATE PROCEDURE [dbo].[GetEquipmentAlerts]
(
	@EDISID INT,
	@From	DATETIME,
	@To		DATETIME,
	@EquipmentSubTypeID INT = 0
)
AS
BEGIN
	SET NOCOUNT ON;

	SELECT	EDISID,
			LastAlarmingReading AS AlertDate,
			InputID AS EquipmentInputID
	FROM EquipmentItems
	JOIN EquipmentTypes ON EquipmentTypes.ID = EquipmentItems.EquipmentTypeID
	WHERE EDISID = @EDISID
	AND (LastAlarmingReading BETWEEN @From AND @To)
	AND (EquipmentSubTypeID = @EquipmentSubTypeID OR @EquipmentSubTypeID = 0)
	
END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetEquipmentAlerts] TO PUBLIC
    AS [dbo];

