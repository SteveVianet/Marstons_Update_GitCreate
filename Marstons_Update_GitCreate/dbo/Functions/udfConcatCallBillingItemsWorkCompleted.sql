﻿CREATE FUNCTION [dbo].[udfConcatCallBillingItemsWorkCompleted] (@id int)  
RETURNS varchar(8000) 
AS
BEGIN 

DECLARE @v varchar(8000)

SELECT @v = COALESCE(@v + char(13), '') + (bi.Description + ' (x' + CAST(cbi.Quantity AS VARCHAR) + ')<br>')
FROM CallBillingItems cbi
	JOIN [SQL1\SQL1].ServiceLogger.dbo.BillingItems bi
		ON bi.ID = cbi.BillingItemID
WHERE cbi.CallID = @id
AND bi.ItemType = 1

RETURN @v

END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[udfConcatCallBillingItemsWorkCompleted] TO PUBLIC
    AS [dbo];

