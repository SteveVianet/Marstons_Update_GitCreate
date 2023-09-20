CREATE FUNCTION [dbo].[udfConcatCallBillingItemsWithLabourMinutes] (@id int)  
RETURNS varchar(8000) 
AS
BEGIN 

DECLARE @v varchar(8000)

SELECT @v = COALESCE(@v + char(13), '') + (bi.Description + '(' + CAST(cbi.LabourMinutes/cbi.Quantity AS VARCHAR) +')'+' ('+'x'+ CAST(cbi.Quantity AS VARCHAR) + ')<br>')
FROM CallBillingItems cbi
	JOIN [SQL1\SQL1].ServiceLogger.dbo.BillingItems bi
		ON bi.ID = cbi.BillingItemID
WHERE cbi.CallID = @id

RETURN @v

END