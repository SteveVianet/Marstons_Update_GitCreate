
CREATE PROCEDURE AddOwnerTradingShift
(
	@OwnerID				INT,
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
FROM OwnerTradingShifts o
WHERE o.OwnerID = @OwnerID
	AND o.[DayOfWeek] = @DayOfWeek
	AND TableNumber = @TableNumber

IF @PrevShift = 0 
BEGIN
	INSERT INTO OwnerTradingShifts
	(
		OwnerID,
		ShiftStartTime,
		ShiftDurationMinutes,
		[DayOfWeek],
		Name,
		TableColour,
		TableNumber
	)
	VALUES
	(
		@OwnerID,
		@ShiftStartTime,
		@ShiftDurationMinutes,
		@DayOfWeek,
		@Name,
		@TableColour,
		@TableNumber
	)
END


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddOwnerTradingShift] TO PUBLIC
    AS [dbo];

