---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE GetScheduleSites
(
	@ScheduleID	INTEGER,
	@DoNotExtend	BIT = 0
)

AS

DECLARE @ExpiryDate DATETIME

SET NOCOUNT ON

IF @DoNotExtend = 0
BEGIN
	-- Get expiry date for selected schedule
	SELECT @ExpiryDate = ExpiryDate
	FROM Schedules
	WHERE [ID] = @ScheduleID

	-- If expiry date is set, then extend it to today+14 days
	IF NOT @ExpiryDate IS NULL
	BEGIN
		UPDATE Schedules
		SET ExpiryDate = DATEADD(d, 14, GETDATE())
		WHERE [ID] = @ScheduleID
	END
END

UPDATE Schedules
SET	UsedOn = GETDATE(),
	UsedBy = SUSER_SNAME()
WHERE [ID] = @ScheduleID

SELECT ScheduleSites.EDISID
FROM dbo.ScheduleSites
JOIN dbo.Sites ON Sites.EDISID = ScheduleSites.EDISID
WHERE ScheduleID = @ScheduleID
ORDER BY Sites.SiteID
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetScheduleSites] TO PUBLIC
    AS [dbo];

