CREATE PROCEDURE dbo.GetFilteredFaultStacks
(
	@EDISID	INT,
	@Filter		VARCHAR(255),
	@From		DATETIME,
	@To		DATETIME
)

AS

SET NOCOUNT ON

DECLARE @MasterDates TABLE([ID] INT NOT NULL, [Date] DATETIME NOT NULL)

INSERT INTO @MasterDates
([ID], [Date])
SELECT [ID], [Date]
FROM MasterDates
--JOIN Sites ON Sites.EDISID = MasterDates.EDISID
WHERE MasterDates.EDISID = @EDISID
AND MasterDates.[Date] BETWEEN @From AND @To
--AND MasterDates.[Date] >= Sites.SiteOnline

IF @Filter = '%' OR @Filter = ''
BEGIN
	SELECT	MasterDates.[Date],
			FaultStack.[Time], 
			FaultStack.[Description]
	FROM dbo.FaultStack
	JOIN @MasterDates AS MasterDates ON MasterDates.[ID] = FaultStack.FaultID
	ORDER BY MasterDates.[Date], FaultStack.[Time]
END
ELSE
BEGIN
	SELECT	MasterDates.[Date],
			FaultStack.[Time], 
			FaultStack.[Description]
	FROM dbo.FaultStack
	JOIN @MasterDates AS MasterDates ON MasterDates.[ID] = FaultStack.FaultID
	WHERE REPLACE(FaultStack.[Description], ' ', '') LIKE REPLACE(@Filter, ' ', '')
	ORDER BY MasterDates.[Date], FaultStack.[Time]
END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetFilteredFaultStacks] TO PUBLIC
    AS [dbo];

