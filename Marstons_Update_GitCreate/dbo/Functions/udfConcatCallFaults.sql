CREATE FUNCTION [dbo].[udfConcatCallFaults] (@id int)  
RETURNS varchar(8000) 
AS
BEGIN 

DECLARE @v varchar(8000)

SELECT @v = COALESCE(@v + char(13), '') + (cft.Description + '; ' + LTRIM(RTRIM(cf.AdditionalInfo)))
FROM CallFaults cf
	JOIN [SQL1\SQL1].ServiceLogger.dbo.CallFaultTypes cft
		ON cft.ID = cf.FaultTypeID
WHERE cf.CallID = @id

RETURN @v

END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[udfConcatCallFaults] TO PUBLIC
    AS [dbo];

