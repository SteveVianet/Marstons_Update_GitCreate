CREATE FUNCTION [dbo].[udfConcatCallFaultsSingleLine] (@id int)  
RETURNS varchar(8000) 
AS
BEGIN 

DECLARE @v varchar(8000)

SELECT @v = COALESCE(@v + char(13), '') + (cft.Description + '; ' + LTRIM(RTRIM(cf.AdditionalInfo)) + ('|'))
FROM CallFaults cf
	JOIN [EDISSQL1\SQL1].ServiceLogger.dbo.CallFaultTypes cft
		ON cft.ID = cf.FaultTypeID
WHERE cf.CallID = @id

RETURN @v

END