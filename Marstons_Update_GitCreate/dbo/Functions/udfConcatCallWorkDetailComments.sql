CREATE FUNCTION [dbo].[udfConcatCallWorkDetailComments] (@id int, @from datetime)  
RETURNS varchar(8000) 
AS
BEGIN 

DECLARE @v varchar(8000)

SELECT @v = COALESCE(@v + ';', '') + 
LTRIM(
	RTRIM(
		(CONVERT(varchar(11), cwdc.SubmittedOn, 113) + ': ' + 
		CONVERT(varchar(8000), cwdc.WorkDetailComment)
		)
	)
)
FROM CallWorkDetailComments cwdc 
WHERE cwdc.CallID = @id
AND cwdc.SubmittedOn > @from

RETURN @v

END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[udfConcatCallWorkDetailComments] TO PUBLIC
    AS [dbo];

