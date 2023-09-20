CREATE FUNCTION [dbo].[udfConcatCallReasonsHeaders] (@id int)  
RETURNS varchar(8000) 
AS
BEGIN 

DECLARE @v varchar(8000)

SELECT @v = COALESCE(@v + char(13), '') + (crt.Description)
FROM CallReasons cr
	JOIN [SQL1\SQL1].ServiceLogger.dbo.CallReasonTypes crt
		ON crt.ID = cr.ReasonTypeID
WHERE cr.CallID = @id

RETURN @v

END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[udfConcatCallReasonsHeaders] TO PUBLIC
    AS [dbo];

