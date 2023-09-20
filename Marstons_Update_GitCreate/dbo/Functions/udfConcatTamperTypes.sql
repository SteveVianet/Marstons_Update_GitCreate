CREATE FUNCTION [dbo].[udfConcatTamperTypes] (@id int)  
RETURNS varchar(8000) 
AS
BEGIN 

DECLARE @v varchar(8000)

SELECT @v = COALESCE(@v + ',', '') + TCETD.[Description]
FROM TamperCaseEventTypeList TCETL 
  JOIN TamperCaseEventTypeDescriptions AS TCETD ON TCETD.[ID] = TCETL.TypeID
WHERE TCETL.RefID = @id

RETURN @v

END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[udfConcatTamperTypes] TO PUBLIC
    AS [dbo];

