CREATE FUNCTION [dbo].[udfLatestCallWorkDetailComment] (@id int)  
RETURNS varchar(8000) 
AS
BEGIN 

DECLARE @v varchar(8000)

SELECT TOP 1 @v = 	
		(CONVERT(varchar(11), cwdc.SubmittedOn, 113) + ' ' + 
		dbo.udfNiceName(cwdc.WorkDetailCommentBy) + ': ' + 
		CONVERT(varchar(8000), cwdc.WorkDetailComment)
		)
FROM CallWorkDetailComments cwdc 
WHERE cwdc.CallID = @id
ORDER BY SubmittedOn DESC

RETURN @v

END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[udfLatestCallWorkDetailComment] TO PUBLIC
    AS [dbo];

