CREATE FUNCTION dbo.GetSiteLastSNACall (@EDISID as int)
RETURNS varchar(1000)
AS
BEGIN
DECLARE @RetVal varchar(1000)
SELECT @RetVal = ''
SELECT TOP 1 @RetVal = 
       CASE CallFaults.FaultTypeID WHEN 2 THEN 'System not answering'
				   WHEN 16 THEN 'System not downloading'
				   WHEN 35 THEN 'SNA - Password Issue'
				   WHEN 41 THEN 'BQM - BOX - Unable to Connect'
				   WHEN 74 THEN 'System disabled PR'
       END
FROM Calls
JOIN CallFaults ON CallFaults.CallID = Calls.[ID]
WHERE EDISID = @EDISID
AND CallFaults.FaultTypeID IN (2, 16, 35, 41, 74)
AND ClosedOn IS NOT NULL
ORDER BY ClosedOn DESC
RETURN (@RetVal)
END



GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSiteLastSNACall] TO PUBLIC
    AS [dbo];

