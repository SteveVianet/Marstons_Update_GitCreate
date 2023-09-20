CREATE PROCEDURE GetSystemStocks
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

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSystemStocks] TO PUBLIC
    AS [dbo];

