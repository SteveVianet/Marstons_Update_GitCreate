CREATE PROCEDURE dbo.GetSiteCallSummary
(
	@EDISID		INTEGER,
	@CallTypeID		INTEGER
)
AS

SELECT RaisedOn,
	 SalesReference
FROM Calls
WHERE CallTypeID = @CallTypeID
AND EDISID = @EDISID
ORDER BY RaisedOn

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSiteCallSummary] TO PUBLIC
    AS [dbo];

