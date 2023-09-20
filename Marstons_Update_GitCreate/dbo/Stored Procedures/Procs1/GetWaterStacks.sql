
/****** Object:  StoredProcedure [dbo].[GetWaterStacks]     Script Date: 07/14/2010 16:25:18 ******/
CREATE PROCEDURE [dbo].[GetWaterStacks]
(
	@EDISID	INT,
	@Date	DATETIME = NULL
)

AS

SELECT WaterStack.[Time],
	WaterStack.Line,
	WaterStack.Volume,
	MasterDates.[Date]
FROM dbo.WaterStack
JOIN dbo.MasterDates
ON MasterDates.[ID] = WaterStack.WaterID
WHERE MasterDates.EDISID = @EDISID
AND ( (MasterDates.[Date] = @Date) OR (@Date IS NULL) )

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetWaterStacks] TO PUBLIC
    AS [dbo];

