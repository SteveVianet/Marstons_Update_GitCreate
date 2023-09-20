CREATE FUNCTION [dbo].[udfConcatTamperCaseTypeIDs] (@CaseID INT, @TypeID INT)  
RETURNS varchar(8000) 
AS
BEGIN 

DECLARE @v varchar(8000)

SET @v = ''

SELECT @v = @v + CAST(TamperCaseEventTypeList.TypeID AS VARCHAR) + ', '
FROM dbo.TamperCaseEvents
JOIN dbo.TamperCaseEventTypeList ON dbo.TamperCaseEventTypeList.RefID = dbo.TamperCaseEvents.TypeListID
WHERE TamperCaseEvents.TypeListID = @TypeID
AND TamperCaseEvents.CaseID = @CaseID

SELECT @v = CASE WHEN LEN(@v) = 0 THEN '' ELSE LEFT(@v, len(@v)-1) END

RETURN @v

END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[udfConcatTamperCaseTypeIDs] TO PUBLIC
    AS [dbo];

