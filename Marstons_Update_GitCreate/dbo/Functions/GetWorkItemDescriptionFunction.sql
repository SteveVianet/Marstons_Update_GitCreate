CREATE FUNCTION [dbo].[GetWorkItemDescriptionFunction] (@CallID as int)
RETURNS varchar(1000)
AS
BEGIN
DECLARE @RetVal varchar(1000)
SELECT @RetVal = ''
SELECT @RetVal=@RetVal + WorkItems.Description + ', '
FROM [SQL1\SQL1].ServiceLogger.dbo.WorkItems AS WorkItems
JOIN CallWorkItems ON CallWorkItems.WorkItemID = WorkItems.[ID]
WHERE CallWorkItems.CallID =@CallID
select @RetVal = CASE WHEN LEN(@RetVal) = 0 THEN '' ELSE left(@RetVal, len(@RetVal)-1) END
RETURN (@RetVal)
END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetWorkItemDescriptionFunction] TO PUBLIC
    AS [dbo];

