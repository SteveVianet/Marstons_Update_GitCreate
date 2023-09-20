CREATE PROCEDURE dbo.GetCleaningProgress
(
	@EDISID	INTEGER,
	@Pump		INTEGER,
	@Date		DATETIME
)
AS

SELECT EDISID,
	 Pump,
	 [Date]
FROM dbo.CleaningProgress
WHERE EDISID = @EDISID
AND Pump = @Pump
AND [Date] = @Date


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetCleaningProgress] TO PUBLIC
    AS [dbo];

