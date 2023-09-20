CREATE PROCEDURE [dbo].[GetFaultStacks]
(
	@EDISID	INT
)
AS

SET NOCOUNT ON

DECLARE @MasterDates TABLE([ID] INT PRIMARY KEY, [Date] DATETIME NOT NULL)

INSERT INTO @MasterDates
([ID], [Date])
SELECT [ID], [Date]
FROM MasterDates
--JOIN Sites ON Sites.EDISID = MasterDates.EDISID
WHERE MasterDates.EDISID = @EDISID
--AND MasterDates.[Date] >= Sites.SiteOnline

SELECT	MasterDates.[Date],
		FaultStack.[Time], 
		FaultStack.[Description]
FROM dbo.FaultStack
JOIN @MasterDates AS MasterDates ON MasterDates.[ID] = FaultStack.FaultID
ORDER BY MasterDates.[Date], FaultStack.[Time]

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetFaultStacks] TO PUBLIC
    AS [dbo];

