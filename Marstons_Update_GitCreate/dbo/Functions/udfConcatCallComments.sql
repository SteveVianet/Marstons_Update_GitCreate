CREATE FUNCTION [dbo].[udfConcatCallComments] (@id int, @from datetime)  
RETURNS varchar(4000) 
AS
BEGIN 

DECLARE @v varchar(4000)

SET @v =
(
SELECT TOP 1 CONVERT(varchar(4000), Comment)
FROM CallComments
WHERE CallID = @id
ORDER BY SubmittedOn DESC
)

RETURN @v

END



GO
GRANT EXECUTE
    ON OBJECT::[dbo].[udfConcatCallComments] TO PUBLIC
    AS [dbo];

