CREATE FUNCTION dbo.GetCallFaultTypesFunction (@CallID as int)
RETURNS varchar(1000)
AS
BEGIN
DECLARE @RetVal varchar(1000)
SELECT @RetVal = ''
SELECT TOP 1 @RetVal=CallFaultTypes.Description
FROM [SQL1\SQL1].ServiceLogger.dbo.CallFaultTypes AS CallFaultTypes
JOIN CallFaults ON CallFaults.FaultTypeID = CallFaultTypes.[ID]
WHERE CallFaults.CallID =@CallID
--select @RetVal = left(@RetVal, len(@RetVal)-1)
RETURN (@RetVal)
END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetCallFaultTypesFunction] TO PUBLIC
    AS [dbo];

