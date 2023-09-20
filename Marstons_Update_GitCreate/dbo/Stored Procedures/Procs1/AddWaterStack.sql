
/****** Object:  StoredProcedure [dbo].[AddWaterStack]      Script Date: 07/14/2010 16:25:18 ******/
CREATE PROCEDURE [dbo].[AddWaterStack]
(
	@EDISID		INT,
	@Date		DATETIME,
	@Time		DATETIME,
	@Line		INT,
	@Volume		FLOAT
)

AS

DECLARE @WaterID		INT
DECLARE @GlobalEDISID	INT

SET NOCOUNT ON

-- Find MasterDate, adding it if we need to
SELECT @WaterID = [ID]
FROM dbo.MasterDates
WHERE [Date] = @Date
AND EDISID = @EDISID

IF @WaterID IS NULL
BEGIN
	INSERT INTO dbo.MasterDates
	(EDISID, [Date])
	VALUES
	(@EDISID, @Date)

	SET @WaterID = @@IDENTITY
END

INSERT INTO dbo.WaterStack
(WaterID, [Time], Line, Volume)
VALUES
(@WaterID, @Time, @Line, @Volume)

SELECT @GlobalEDISID = GlobalEDISID
FROM Sites
WHERE EDISID = @EDISID

IF @GlobalEDISID IS NOT NULL
BEGIN
	EXEC [SQL2\SQL2].[Global].dbo.AddWaterStack @GlobalEDISID, @Date, @Time, @Line, @Volume
END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddWaterStack] TO PUBLIC
    AS [dbo];

