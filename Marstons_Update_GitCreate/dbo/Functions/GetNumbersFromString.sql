CREATE FUNCTION [dbo].[GetNumbersFromString] (@String VARCHAR(1000))
RETURNS varchar(1000)
AS
BEGIN
	WHILE PATINDEX('%[^0-9]%',@String) <> 0
		SET @String = STUFF(@String,PATINDEX('%[^0-9]%',@String),1,'')

	RETURN @String

END


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetNumbersFromString] TO PUBLIC
    AS [dbo];

