CREATE PROCEDURE [dbo].[GetSystemStockStatus]
(
	@InStock		BIT,
	@MonthThreshold	INTEGER = 0
)
AS

IF @InStock = 1
BEGIN
	SELECT [ID],
		DateIn,
		DateOut,
		OldInstallDate,
		EDISID,
		SystemTypeID,
		CallID,
		PreviousEDISID,
		PreviousName,
		PreviousPostcode,
		PreviousFMCount,
		WrittenOff,
		Comment
	FROM dbo.SystemStock
	WHERE DateOut IS NULL
	AND OldInstallDate > DATEADD(month, @MonthThreshold * -1, GETDATE())
	AND WrittenOff = 0
	ORDER BY OldInstallDate DESC
END
ELSE
BEGIN
	SELECT [ID],
		DateIn,
		DateOut,
		OldInstallDate,
		EDISID,
		SystemTypeID,
		CallID,
		PreviousEDISID,
		PreviousName,
		PreviousPostcode,
		PreviousFMCount,
		WrittenOff,
		Comment
	FROM dbo.SystemStock
	WHERE DateOut IS NOT NULL
	AND WrittenOff = 0

END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSystemStockStatus] TO PUBLIC
    AS [dbo];

