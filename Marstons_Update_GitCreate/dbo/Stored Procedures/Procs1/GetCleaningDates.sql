---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE GetCleaningDates
(
	@EDISID	INT
)

AS


DECLARE @iEDISID AS INTEGER
SET @iEDISID = @EDISID



SELECT MD.[Date]
FROM (SELECT ID, EDISID, Date FROM MasterDates WHERE EDISID = @iEDISID) AS MD
JOIN dbo.CleaningStack
ON CleaningStack.CleaningID = MD.[ID]
GROUP BY MD.[Date]

--SELECT MasterDates.[Date]
--FROM dbo.CleaningStack
--JOIN dbo.MasterDates
--ON MasterDates.[ID] = CleaningStack.CleaningID
--WHERE MasterDates.EDISID = @EDISID
--GROUP BY MasterDates.[Date]

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetCleaningDates] TO PUBLIC
    AS [dbo];

