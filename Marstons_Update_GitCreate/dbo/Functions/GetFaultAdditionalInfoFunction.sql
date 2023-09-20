CREATE FUNCTION dbo.GetFaultAdditionalInfoFunction (@CallID as int)
RETURNS varchar(1000)
AS
BEGIN
DECLARE @RetVal varchar(1000)
SELECT @RetVal = ''
SELECT @RetVal=@RetVal + CallFaults.AdditionalInfo + ', '
FROM CallFaults
--JOIN CallWorkItems ON CallWorkItems.WorkItemID = WorkItems.[ID]
WHERE CallFaults.CallID =@CallID
select @RetVal = left(@RetVal, len(@RetVal)-1)
RETURN (@RetVal)
END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetFaultAdditionalInfoFunction] TO PUBLIC
    AS [dbo];

