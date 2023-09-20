CREATE PROCEDURE GetWrittenOffStock
(
	@MonthThreshold	INTEGER = 0
)
AS

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
AND (OldInstallDate < DATEADD(month, @MonthThreshold * -1, GETDATE()) OR WrittenOff = 1)

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetWrittenOffStock] TO PUBLIC
    AS [dbo];

