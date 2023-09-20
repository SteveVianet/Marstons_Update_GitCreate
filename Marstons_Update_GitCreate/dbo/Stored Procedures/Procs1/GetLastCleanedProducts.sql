CREATE PROCEDURE GetLastCleanedProducts
	@EDISID INT,
	@LimitDate DATE = NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SET @LimitDate = ISNULL(@LimitDate, GETDATE())
	
    DECLARE @LastCleanedDates TABLE (
		EDISID INT,
		Line INT,
		RealLine INT,
		LastCleaned DATETIME
		)

	INSERT INTO @LastCleanedDates
	EXEC GetLastCleanedDates @EDISID, @LimitDate

	SELECT lcd.*, ps.ProductID, p.Description AS Product, l.Description AS Location, ps.InUse
	FROM @LastCleanedDates AS lcd
	JOIN PumpSetup AS ps
		ON ps.EDISID = lcd.EDISID AND ps.Pump = lcd.Line
	JOIN Products AS p
		ON p.ID = ps.ProductID
	JOIN Locations AS l
		ON l.ID = ps.LocationID
	WHERE lcd.LastCleaned BETWEEN ps.ValidFrom AND ISNULL(ps.ValidTo, GETDATE())
END
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetLastCleanedProducts] TO PUBLIC
    AS [dbo];

