CREATE PROCEDURE [dbo].[GetAuditorNewFontSetups]
AS

SET NOCOUNT ON

DECLARE @CustomerID INT
SELECT @CustomerID = CAST(PropertyValue AS INTEGER)
FROM Configuration
WHERE PropertyName = 'Service Owner ID'

SELECT @CustomerID AS Customer,
	   ProposedFontSetups.EDISID,
	   CASE WHEN Calls.[ID] IS NULL THEN NULL ELSE dbo.GetCallReference(Calls.[ID]) END AS CallReference,
	   dbo.udfNiceName(ProposedFontSetups.UserName) AS Calibrator,
	   ProposedFontSetups.CreateDate,
	   CASE WHEN Sites.Hidden = 1 THEN 1 ELSE 0 END AS NewInstall
FROM ProposedFontSetups
JOIN Sites ON Sites.EDISID = ProposedFontSetups.EDISID
LEFT JOIN dbo.Calls ON Calls.[ID] = ProposedFontSetups.CallID
WHERE ProposedFontSetups.Available = 1
AND ProposedFontSetups.Completed = 0
AND Calls.AbortReasonID = 0
AND Calls.CallTypeID = 2

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetAuditorNewFontSetups] TO PUBLIC
    AS [dbo];

