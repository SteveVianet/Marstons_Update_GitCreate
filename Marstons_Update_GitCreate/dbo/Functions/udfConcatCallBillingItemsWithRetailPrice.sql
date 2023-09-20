CREATE FUNCTION [dbo].[udfConcatCallBillingItemsWithRetailPrice] (@id int, @excludeid int)  
RETURNS varchar(8000) 
AS
BEGIN 

DECLARE @v varchar(8000)

SELECT @v = COALESCE(@v + char(13), '') + (bi.Description + ' £' + CAST(ROUND(cbi.FullRetailPrice,2) AS VARCHAR) + ' (x' + CAST(cbi.Quantity AS VARCHAR) + '), ')
FROM CallBillingItems cbi
	JOIN [SQL1\SQL1].ServiceLogger.dbo.BillingItems bi
		ON bi.ID = cbi.BillingItemID
WHERE cbi.CallID = @id
AND ItemType = 1
AND cbi.BillingItemID <> @excludeid

RETURN @v

END
