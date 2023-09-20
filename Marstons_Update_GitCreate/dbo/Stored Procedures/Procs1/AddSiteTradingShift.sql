
CREATE PROCEDURE AddSiteTradingShift
(
	@EDISID					INT,
	@ShiftStartTime			DATETIME,
	@ShiftDurationMinutes	INT,
	@Name					VARCHAR(100),
	@DayOfWeek				INT,
	@TableColour			VARCHAR(50),
	@TableNumber			INT
)

AS

SET NOCOUNT ON;

DECLARE @PrevShift AS INTEGER

SELECT @PrevShift = COUNT(*)
FROM SiteTradingShifts s
WHERE s.EDISID = @EDISID
	AND s.[DayOfWeek] = @DayOfWeek
	AND TableNumber = @TableNumber

IF @PrevShift = 0 
BEGIN
	INSERT INTO SiteTradingShifts
	(
		EDISID,
		ShiftStartTime,
		ShiftDurationMinutes,
		[DayOfWeek],
		Name,
		ManuallyAdjustedBySiteUser,
		TableColour,
		TableNumber
	)
	VALUES
	(
		@EDISID,
		@ShiftStartTime,
		@ShiftDurationMinutes,
		@DayOfWeek,
		@Name,
		0,
		@TableColour,
		@TableNumber
	)
END


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddSiteTradingShift] TO PUBLIC
    AS [dbo];

