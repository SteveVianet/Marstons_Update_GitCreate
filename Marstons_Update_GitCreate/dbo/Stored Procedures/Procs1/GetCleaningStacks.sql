
/****** Object:  StoredProcedure [dbo].[GetCleaningStacks]  Script Date: 07/14/2010 16:25:18 ******/
CREATE PROCEDURE [dbo].[GetCleaningStacks]
(
	@EDISID	INT,
	@Date	DATETIME = NULL
)

AS

SELECT CleaningStack.[Time],
	CleaningStack.Line,
	CleaningStack.Volume,
	MasterDates.[Date]
FROM dbo.CleaningStack
JOIN dbo.MasterDates
ON MasterDates.[ID] = CleaningStack.CleaningID
WHERE MasterDates.EDISID = @EDISID
AND ( (MasterDates.[Date] = @Date) OR (@Date IS NULL) )

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetCleaningStacks] TO PUBLIC
    AS [dbo];

