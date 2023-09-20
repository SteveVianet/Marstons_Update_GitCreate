CREATE PROCEDURE [dbo].[GetVisitRecordTampering]
	@IncludeDepricated BIT = 1
AS

SET NOCOUNT ON

DECLARE @Tampering AS TABLE ([ID] INT, [Description] NVARCHAR(100))
INSERT INTO @Tampering EXEC [SQL1\SQL1].[ServiceLogger].[dbo].GetVRSTampering

SELECT TamperingID, [Description]
FROM VRSTampering
JOIN @Tampering AS Tampering ON Tampering.[ID] = TamperingID
WHERE Depricated = 0 OR @IncludeDepricated = 1

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetVisitRecordTampering] TO PUBLIC
    AS [dbo];

