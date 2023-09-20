CREATE PROCEDURE [dbo].[DeleteEquipmentLog]
(
	@EDISID 			INT, 
	@Date				DATETIME,
	@SlaveID			INT,
	@InputID			INT,
	@IsDigital			BIT,
	@Time				DATETIME
)

AS

DECLARE @MasterDateID	INTEGER
DECLARE @GlobalEDISID	INTEGER

SET NOCOUNT ON

-- Find MasterDateID
SELECT @MasterDateID = [ID]
FROM dbo.MasterDates
WHERE EDISID = @EDISID
AND [Date] = @Date

/*
-- Delete from EquipmentLogs table
DELETE FROM dbo.EquipmentLogs
WHERE MasterDateID = @MasterDateID
AND InputID = @InputID
AND dbo.fnTimePart(EquipmentLogs.[Time]) = dbo.fnTimePart(@Time)
*/

DELETE FROM dbo.EquipmentReadings
WHERE EDISID = @EDISID
AND InputID = @InputID
AND LogDate = CONVERT(VARCHAR(19), DATEADD(ss, DATEPART(ss, @Time), DATEADD(mi, DATEPART(mi, @Time), DATEADD(hh, DATEPART(hh, @Time), 
@Date))), 20)

/*
SELECT @GlobalEDISID = GlobalEDISID
FROM Sites
WHERE EDISID = @EDISID

IF @GlobalEDISID IS NOT NULL
BEGIN
	EXEC [SQL2\SQL2].[Global].dbo.DeleteEquipmentLog @GlobalEDISID, @Date, @SlaveID, @InputID, @IsDigital, @Time
END
*/


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[DeleteEquipmentLog] TO PUBLIC
    AS [dbo];

