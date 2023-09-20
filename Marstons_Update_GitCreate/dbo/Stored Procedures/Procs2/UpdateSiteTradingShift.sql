CREATE PROCEDURE [dbo].[UpdateSiteTradingShift]
(
	@EDISID					INT,
	@ID						INT,
	@ShiftStartTime			DATETIME,
	@ShiftDurationMinutes	INT,
	@Name					VARCHAR(100),
	@DayOfWeek				INT,
	@TableColour			VARCHAR(50) = NULL,
	@TableNumber			INT = NULL
)

AS

UPDATE dbo.SiteTradingShifts
SET 
    ShiftStartTime = @ShiftStartTime,
	ShiftDurationMinutes =	@ShiftDurationMinutes,
	DayOfWeek = 	@DayOfWeek,
	Name =	@Name,
	TableColour =	@TableColour,
	TableNumber =	@TableNumber,
	ManuallyAdjustedBySiteUser = 1
WHERE EDISID = @EDISID AND ID = @ID
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateSiteTradingShift] TO PUBLIC
    AS [dbo];

