CREATE FUNCTION [dbo].[udfConcatCallReasonsSingleLine] (@id int)  
RETURNS varchar(8000) 
AS
BEGIN 

DECLARE @v varchar(8000)

SELECT @v = COALESCE(@v + char(13), '') + (crt.Description + '; ' + LTRIM(RTRIM(cr.AdditionalInfo)) + ('|'))
FROM CallReasons cr
	JOIN [EDISSQL1\SQL1].ServiceLogger.dbo.CallReasonTypes crt
		ON crt.ID = cr.ReasonTypeID
WHERE cr.CallID = @id

--RETURN LEFT(@v, LEN(@v) - 2)
RETURN @v

END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[udfConcatCallReasonsSingleLine] TO PUBLIC
    AS [dbo];

