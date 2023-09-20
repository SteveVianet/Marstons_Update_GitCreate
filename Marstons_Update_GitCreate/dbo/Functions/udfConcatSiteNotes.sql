CREATE FUNCTION [dbo].[udfConcatSiteNotes] (@EDISID AS INT)
RETURNS VARCHAR(1000)
AS
BEGIN
DECLARE @RetVal VARCHAR(1000)
SELECT @RetVal = ''
SELECT @RetVal=@RetVal + [Text] + ', '
FROM SiteComments
WHERE [Type] = 5
AND EDISID = @EDISID
select @RetVal = CASE WHEN LEN(@RetVal) = 0 THEN '' ELSE left(@RetVal, len(@RetVal)-1) END
RETURN (@RetVal)
END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[udfConcatSiteNotes] TO PUBLIC
    AS [dbo];

