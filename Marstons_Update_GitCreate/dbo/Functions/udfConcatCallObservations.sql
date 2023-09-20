CREATE FUNCTION [dbo].[udfConcatCallObservations] (@id int)  
RETURNS varchar(8000) 
AS
BEGIN 

DECLARE @v varchar(8000)

SELECT @v = COALESCE(@v + char(13), '') + (bi.Description + ', ')
FROM CallBillingItems cbi
	JOIN [SQL1\SQL1].ServiceLogger.dbo.BillingItems bi
		ON bi.ID = cbi.BillingItemID
WHERE cbi.CallID = @id
AND ItemType = 2

RETURN @v

END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[udfConcatCallObservations] TO PUBLIC
    AS [dbo];

