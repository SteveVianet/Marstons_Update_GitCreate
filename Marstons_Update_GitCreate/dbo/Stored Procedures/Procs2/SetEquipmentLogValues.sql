

CREATE PROCEDURE SetEquipmentLogValues
(
	@EDISID			INT,
	@Date			DATETIME,
	@Time			DATETIME,
	@SlaveID		INT,
	@IsDigital		BIT,
	@InputID		INT,
	@Value1			FLOAT,
	@Value2			FLOAT,
	@Value3			FLOAT
)

AS

UPDATE dbo.EquipmentReadings
SET	Value = @Value1
WHERE LogDate = CONVERT(VARCHAR(19), DATEADD(ss, DATEPART(ss, @Time), DATEADD(mi, DATEPART(mi, @Time), DATEADD(hh, DATEPART(hh, @Time), 
@Date))), 20)
AND EDISID = @EDISID
AND InputID = @InputID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[SetEquipmentLogValues] TO PUBLIC
    AS [dbo];

