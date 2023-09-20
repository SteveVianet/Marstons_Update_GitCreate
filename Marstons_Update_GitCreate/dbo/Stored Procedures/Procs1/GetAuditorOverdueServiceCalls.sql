CREATE PROCEDURE dbo.GetAuditorOverdueServiceCalls
AS

SET NOCOUNT ON

DECLARE @OverdueCalls TABLE(CallID INT NOT NULL, EDISID INT NOT NULL, CallTypeID INT NOT NULL, RaisedOn DATETIME NOT NULL)

DECLARE @CustomerID INT
SELECT @CustomerID = CAST(PropertyValue AS INTEGER)
FROM Configuration
WHERE PropertyName = 'Service Owner ID'

INSERT INTO @OverdueCalls
(CallID, EDISID, CallTypeID, RaisedOn)
SELECT Calls.[ID],
	   Calls.EDISID,
	   Calls.CallTypeID,
	   Calls.RaisedOn
FROM Calls
JOIN CallStatusHistory ON CallStatusHistory.CallID = Calls.[ID] AND CallStatusHistory.StatusID <> 6
WHERE RaisedOn < DATEADD(day, -7, GETDATE())
GROUP BY Calls.[ID],
	   Calls.EDISID,
	   Calls.CallTypeID,
	   Calls.RaisedOn
HAVING MAX(CallStatusHistory.StatusID) NOT IN (2, 4)

SELECT @CustomerID AS Customer,
	   OverdueCalls.EDISID,
	   OverdueCalls.CallTypeID,
	   OverdueCalls.RaisedOn,
	   dbo.GetCallReference(OverdueCalls.CallID) AS CallRef,
	   DATEDIFF(day, OverdueCalls.RaisedOn, GETDATE()) AS [Days],
	   MAX(CallComments.SubmittedOn) AS LastComment
FROM @OverdueCalls AS OverdueCalls
LEFT JOIN CallComments ON CallComments.CallID = OverdueCalls.CallID
GROUP BY OverdueCalls.EDISID,
	   OverdueCalls.CallTypeID,
	   OverdueCalls.RaisedOn,
	   dbo.GetCallReference(OverdueCalls.CallID),
	   DATEDIFF(day, OverdueCalls.RaisedOn, GETDATE())

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetAuditorOverdueServiceCalls] TO PUBLIC
    AS [dbo];

